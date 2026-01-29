import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'repositories/online_game_repository.dart';
import 'core/localization/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/env_config.dart';
import 'services/notification_service.dart';

/// Main app widget
class OukChaktrongApp extends StatefulWidget {
  final EnvConfig config;
  const OukChaktrongApp({super.key, required this.config});

  @override
  State<OukChaktrongApp> createState() => _OukChaktrongAppState();
}

class _OukChaktrongAppState extends State<OukChaktrongApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationCallbacks();
    
    // Process any pending notification after first frame (cold start from notification)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationService.processPendingNotification();
    });
  }

  void _setupNotificationCallbacks() {
    // When host taps notification (from background or foreground) → show dialog
    notificationService.onJoinNowTapped = (roomId) {
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        // Get guest name from the notification data
        // For now, we'll use a generic message since we don't store it
        _showJoinRequestDialog(context, roomId, 'A player');
      }
    };

    // When host taps "Cancel" on notification
    notificationService.onCancelTapped = (roomId) {
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        // Decline the request
        GoRouter.of(context).go('/lobby');
      }
    };

    // When foreground and not on waiting screen → show alert dialog
    notificationService.onForegroundJoinRequest = (roomId, guestName) {
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        // Check if not already on game screen or lobby (lobby auto-accepts)
        final currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath;
        if (currentRoute.contains('/online-game/') || currentRoute.contains('/lobby')) {
          // Already on game or lobby - don't show dialog
          return;
        }
        _showJoinRequestDialog(context, roomId, guestName);
      }
    };
  }

  void _showJoinRequestDialog(BuildContext context, String roomId, String guestName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2A1A4A),
          title: const Text('Join Request', style: TextStyle(color: Colors.white)),
          content: Text(
            '$guestName wants to join your game',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Decline - navigate to lobby which will handle cleanup
                GoRouter.of(context).go('/lobby');
              },
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                // Accept - update Firestore first, then navigate
                try {
                  await OnlineGameRepository().acceptJoinRequest(roomId);
                } catch (e) {
                  debugPrint('Failed to accept join request: $e');
                }
                // Navigate to game
                GoRouter.of(context).go('/online-game/$roomId');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OutChaktrongAppBloc(),
      child: BlocBuilder<OutChaktrongAppBloc, OutChaktrongAppState>(
        buildWhen: (previous, current) => previous.local != current.local,
        builder: (context, state) {
          return MaterialApp.router(
            title: widget.config.appName,
            locale: Locale(state.local),
            debugShowCheckedModeBanner: widget.config.isUat,
            theme: AppTheme.darkTheme,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              if (widget.config.isUat) {
                return Banner(
                  message: "UAT",
                  location: BannerLocation.topEnd,
                  color: Colors.red,
                  child: child!,
                );
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}

class OutChaktrongAppState extends Equatable {
  final String local;

  const OutChaktrongAppState({required this.local});

  OutChaktrongAppState copyWith({String? local}) {
    return OutChaktrongAppState(local: local ?? this.local);
  }

  @override
  List<Object?> get props => [local];
}

class OutChaktrongAppBloc extends Cubit<OutChaktrongAppState> {
  OutChaktrongAppBloc() : super(OutChaktrongAppState(local: "en")) {
    _init();
  }

  void _init() async {
    String local = await appStrings.getLanguage();
    emit(state.copyWith(local: local));
  }

  void updateLanguage(String local) async {
    await appStrings.setLanguage(local);
    emit(state.copyWith(local: local));
  }
}
