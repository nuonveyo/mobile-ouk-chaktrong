const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function: Send push notification to host when someone requests to join
 * Triggers when a game room is updated
 */
exports.onJoinRequest = functions
  .region("asia-southeast1")
  .firestore.document("games/{roomId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const roomId = context.params.roomId;

    // Check if status changed to pendingJoin
    if (before.status !== "pendingJoin" && after.status === "pendingJoin") {
      const hostFcmToken = after.hostFcmToken;
      const guestName = after.pendingGuestName || "Someone";

      if (!hostFcmToken) {
        console.log("No FCM token for host, skipping notification");
        return null;
      }

      // Build the notification message
      const message = {
        token: hostFcmToken,
        notification: {
          title: "Join Request",
          body: `${guestName} wants to join your game`,
        },
        data: {
          type: "join_request",
          roomId: roomId,
          guestName: guestName,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "join_requests",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: "Join Request",
                body: `${guestName} wants to join your game`,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      try {
        const response = await messaging.send(message);
        console.log("Successfully sent notification:", response);
        return response;
      } catch (error) {
        console.error("Error sending notification:", error);
        return null;
      }
    }

    return null;
  });

/**
 * Cloud Function: Clean up expired rooms (TTL)
 * Runs every hour to delete rooms that have passed their expiresAt time
 */
exports.cleanupExpiredRooms = functions
  .region("asia-southeast1")
  .pubsub.schedule("every 60 minutes")
  .onRun(async (context) => {
    const now = new Date().toISOString();

    const expiredRooms = await db
      .collection("games")
      .where("expiresAt", "<", now)
      .where("status", "in", ["waiting", "pendingJoin"])
      .get();

    const batch = db.batch();
    expiredRooms.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${expiredRooms.size} expired rooms`);
    return null;
  });
