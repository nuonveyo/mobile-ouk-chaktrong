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
          
          // Navigate to game when it starts
          if (state.isGameStarted && state.currentRoom != null) {
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
            onCreateRoom: () => _showCreateRoomDialog(context),
            onJoinRoom: (roomId) {
              context.read<OnlineGameBloc>().add(JoinRoomRequested(roomId));
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
  final VoidCallback onCreateRoom;
  final void Function(String) onJoinRoom;

  const _RoomList({
    required this.rooms,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Create room button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
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
        ),
        
        const Divider(color: AppColors.surfaceLight),
        
        // Available rooms header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
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
        ),
        
        // Room list
        Expanded(
          child: rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return _RoomCard(
                      room: room,
                      onJoin: () => onJoinRoom(room.id),
                    );
                  },
                ),
        ),
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
