import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../models/models.dart';
import '../../blocs/online/online_game_bloc.dart';
import '../../repositories/repositories.dart';

/// Lobby screen for online multiplayer
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnlineGameBloc(
        authRepository: AuthRepository(),
        gameRepository: OnlineGameRepository(),
      ),
      child: const _LobbyScreenContent(),
    );
  }
}

class _LobbyScreenContent extends StatelessWidget {
  const _LobbyScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(appStrings.onlineLobby),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OnlineGameBloc>().add(const RefreshRoomsRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<OnlineGameBloc, OnlineGameBlocState>(
        listenWhen: (previous, current) =>
            previous.isWaitingForOpponent != current.isWaitingForOpponent ||
            previous.isGameStarted != current.isGameStarted ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          // Show error messages
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          
          // Navigate to game when it starts (only for players, spectators stay in SpectatorScreen)
          if (state.isGameStarted && state.currentRoom != null && !state.isSpectating) {
            context.go('/online-game/${state.currentRoom!.id}');
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.templeGold),
            );
          }

          // Show waiting screen if hosting a room
          if (state.isWaitingForOpponent) {
            return _WaitingForOpponent(
              roomId: state.currentRoom!.id,
              onCancel: () {
                context.read<OnlineGameBloc>().add(const LeaveRoomRequested());
              },
            );
          }

          return _RoomList(
            rooms: state.availableRooms,
            activeGames: state.activeGames,
            onCreateRoom: () => _showCreateRoomDialog(context),
            onJoinRoom: (roomId) {
              context.read<OnlineGameBloc>().add(JoinRoomRequested(roomId));
            },
            onWatchGame: (roomId) {
              context.read<OnlineGameBloc>().add(WatchAsSpectatorRequested(roomId));
              context.go('/spectate/$roomId');
            },
          );
        },
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    int selectedTime = 600; // 10 minutes default
    
    // Capture the bloc before showing dialog
    final bloc = context.read<OnlineGameBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(appStrings.createGameRoom),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${appStrings.timeControl}:'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _TimeChip(
                    label: '5 min',
                    isSelected: selectedTime == 300,
                    onTap: () => setState(() => selectedTime = 300),
                  ),
                  _TimeChip(
                    label: '10 min',
                    isSelected: selectedTime == 600,
                    onTap: () => setState(() => selectedTime = 600),
                  ),
                  _TimeChip(
                    label: '15 min',
                    isSelected: selectedTime == 900,
                    onTap: () => setState(() => selectedTime = 900),
                  ),
                  _TimeChip(
                    label: '20 min',
                    isSelected: selectedTime == 1200,
                    onTap: () => setState(() => selectedTime = 1200),
                  ),
                  _TimeChip(
                    label: '30 min',
                    isSelected: selectedTime == 1800,
                    onTap: () => setState(() => selectedTime = 1800),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(appStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                bloc.add(CreateRoomRequested(timeControl: selectedTime));
              },
              child: Text(appStrings.create),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.templeGold : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.deepPurple : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  final List<OnlineGameRoom> rooms;
  final List<OnlineGameRoom> activeGames;
  final VoidCallback onCreateRoom;
  final void Function(String) onJoinRoom;
  final void Function(String) onWatchGame;

  const _RoomList({
    required this.rooms,
    required this.activeGames,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onWatchGame,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Create room button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCreateRoom,
            icon: const Icon(Icons.add),
            label: Text(appStrings.createRoom),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        const Divider(color: AppColors.surfaceLight),
        const SizedBox(height: 8),
        
        // Live Games section (for spectating)
        if (activeGames.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.live_tv, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                '${appStrings.liveGames} (${activeGames.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activeGames.map((game) => _LiveGameCard(
            room: game,
            onWatch: () => onWatchGame(game.id),
          )),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 8),
        ],
        
        // Available rooms header
        Row(
          children: [
            const Icon(Icons.groups, color: AppColors.templeGold, size: 20),
            const SizedBox(width: 8),
            Text(
              '${appStrings.availableRooms} (${rooms.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Room list
        if (rooms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  appStrings.noRoomsAvailable,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  appStrings.createRoomToStart,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...rooms.map((room) => _RoomCard(
            room: room,
            onJoin: () => onJoinRoom(room.id),
          )),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final OnlineGameRoom room;
  final VoidCallback onJoin;

  const _RoomCard({
    required this.room,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = room.timeControl ~/ 60;
    
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.templeGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.sports_esports,
            color: AppColors.templeGold,
          ),
        ),
        title: Text(
          room.hostPlayerName ?? appStrings.player,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${appStrings.minFormat(minutes)} • ${appStrings.waitingOpponentShort}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        trailing: ElevatedButton(
          onPressed: onJoin,
          child: Text(appStrings.join),
        ),
      ),
    );
  }
}

class _LiveGameCard extends StatelessWidget {
  final OnlineGameRoom room;
  final VoidCallback onWatch;

  const _LiveGameCard({
    required this.room,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = room.timeControl ~/ 60;
    final hostName = room.hostPlayerName ?? 'Player 1';
    final guestName = room.guestPlayerName ?? 'Player 2';
    
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.live_tv,
            color: Colors.red,
          ),
        ),
        title: Text(
          '$hostName vs $guestName',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${appStrings.minFormat(minutes)}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            if (room.spectatorCount > 0) ...[
              const SizedBox(width: 8),
              Icon(Icons.visibility, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '${room.spectatorCount}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
        trailing: OutlinedButton.icon(
          onPressed: onWatch,
          icon: const Icon(Icons.visibility, size: 18),
          label: Text(appStrings.watch),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

class _WaitingForOpponent extends StatelessWidget {
  final String roomId;
  final VoidCallback onCancel;

  const _WaitingForOpponent({
    required this.roomId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.templeGold),
            const SizedBox(height: 32),
            Text(
              appStrings.waitingForOpponent,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${appStrings.room}: ${roomId.substring(0, 8)}...',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: onCancel,
              child: Text(appStrings.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
