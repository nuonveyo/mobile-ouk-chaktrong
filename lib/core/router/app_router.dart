import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/game/game_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/lobby/lobby_screen.dart';
import '../../screens/test/test_scenarios_screen.dart';
import '../../core/constants/game_constants.dart';

/// App router configuration using GoRouter
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game',
        name: 'game',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return GameScreen(
            gameMode: extra?['gameMode'] as GameMode? ?? GameMode.local2Player,
            aiDifficulty: extra?['aiDifficulty'] as AiDifficulty?,
            timeControl: extra?['timeControl'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/lobby',
        name: 'lobby',
        builder: (context, state) => const LobbyScreen(),
      ),
      GoRoute(
        path: '/test',
        name: 'test',
        builder: (context, state) => const TestScenariosScreen(),
      ),
    ],
  );
}

