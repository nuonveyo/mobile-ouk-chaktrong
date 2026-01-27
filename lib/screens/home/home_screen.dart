import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/remote_config_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../app.dart';

/// Home screen with game mode selection
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    // Small delay to ensure the UI is ready
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final config = await RemoteConfigService().checkUpdate();
    if (config != null && mounted) {
      _showUpdateDialog(config);
    }
  }

  void _showUpdateDialog(UpdateConfig config) {
    final String currentLocale = BlocProvider.of<OutChaktrongAppBloc>(context).state.local;
    
    showDialog(
      context: context,
      barrierDismissible: !config.mandatory,
      builder: (context) => PopScope(
        canPop: !config.mandatory,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            config.getLocalizedTitle(currentLocale),
            style: const TextStyle(color: AppColors.templeGold, fontWeight: FontWeight.bold),
          ),
          content: Text(
            config.getLocalizedMessage(currentLocale),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            if (!config.mandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appStrings.cancel),
              ),
            ElevatedButton(
              onPressed: () async {
                final Uri url = Uri.parse(config.storeUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.templeGold,
                foregroundColor: AppColors.deepPurple,
              ),
              child: Text(appStrings.updateNow),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OutChaktrongAppBloc, OutChaktrongAppState>(
      buildWhen: (previous, current) => previous.local != current.local,
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.deepPurple,
                  Color(0xFF0D0518),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    // Logo section
                    _buildLogo(),
                    const Spacer(flex: 1),
                    // Game mode buttons
                    _buildGameModeButton(
                      context,
                      icon: Icons.smart_toy_outlined,
                      label: appStrings.playVsAi,
                      sublabel: appStrings.challengeComputer,
                      onTap: () => _showAiDifficultyDialog(context),
                    ),
                    const SizedBox(height: 16),
                    _buildGameModeButton(
                      context,
                      icon: Icons.people_outline,
                      label: appStrings.local2Players,
                      sublabel: appStrings.playWithFriend,
                      onTap: () => context.push('/game', extra: {
                        'gameMode': GameMode.local2Player,
                      }),
                    ),
                    const SizedBox(height: 16),
                    _buildGameModeButton(
                      context,
                      icon: Icons.public_outlined,
                      label: appStrings.onlineMatch,
                      sublabel: appStrings.playWorldwide,
                      onTap: () => context.push('/lobby'),
                    ),
                    const Spacer(flex: 2),
                    // Bottom navigation
                    _buildBottomNav(context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Decorative temple icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.warmGold, AppColors.templeGold],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.templeGold.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.castle_outlined,
            size: 50,
            color: AppColors.deepPurple,
          ),
        ),
        const SizedBox(height: 24),
        // Khmer title
        const Text(
          'អុកចត្រង្គ',
          style: TextStyle(
            fontFamily: 'Battambang',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.templeGold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'OUK CHAKTRONG',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGameModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.templeGold.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.templeGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.templeGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.templeGold,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(Icons.home_filled, appStrings.home, true),
        _buildNavItem(Icons.leaderboard_outlined, appStrings.ranks, false),
        _buildNavItem(
          Icons.bug_report_outlined,
          appStrings.test,
          false,
          onTap: () => context.push('/test'),
        ),
        _buildNavItem(
          Icons.settings_outlined,
          appStrings.settings,
          false,
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.templeGold : AppColors.textMuted,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppColors.templeGold : AppColors.textMuted,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showAiDifficultyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appStrings.selectDifficulty,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildDifficultyOption(
              context,
              appStrings.easy,
              appStrings.perfectForBeginners,
              AiDifficulty.easy,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildDifficultyOption(
              context,
              appStrings.medium,
              appStrings.balancedChallenge,
              AiDifficulty.medium,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildDifficultyOption(
              context,
              appStrings.hard,
              appStrings.forExperienced,
              AiDifficulty.hard,
              Colors.red,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    String label,
    String description,
    AiDifficulty difficulty,
    Color indicatorColor,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.push('/game', extra: {
            'gameMode': GameMode.vsAi,
            'aiDifficulty': difficulty,
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
