import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../services/sound_service.dart';
import '../../repositories/user_repository.dart';
import '../../models/user.dart';

/// Settings screen with sound, vibration, and language options
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'en';
  User? _user;
  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await appStrings.init();
    await SoundService().init();
    
    final user = await _userRepository.getUser();
    
    setState(() {
      _soundEnabled = SoundService().soundEnabled;
      _selectedLanguage = appStrings.locale.languageCode;
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(appStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Player Stats Section
          _buildSection(
            'Player Stats',
            [
              _buildInfoTile(
                icon: Icons.person,
                title: 'Username',
                subtitle: _user?.name ?? 'Loading...',
                onTap: () => _showEditProfileDialog(),
              ),
              // _buildInfoTile(
              //   icon: Icons.email_outlined,
              //   title: 'Email',
              //   subtitle: _user?.email ?? 'Not set',
              //   onTap: () => _showEditProfileDialog(),
              // ),
              // _buildInfoTile(
              //   icon: Icons.phone_outlined,
              //   title: 'Phone',
              //   subtitle: _user?.phoneNumber ?? 'Not set',
              //   onTap: () => _showEditProfileDialog(),
              // ),
              _buildInfoTile(
                icon: Icons.emoji_events,
                title: 'Total Points',
                subtitle: '🏆 ${_user?.points ?? 0} pts',
              ),
              // ListTile(
              //   leading: const Icon(Icons.edit, color: AppColors.templeGold),
              //   title: const Text('Edit Profile', style: TextStyle(color: AppColors.templeGold)),
              //   trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              //   onTap: () => _showEditProfileDialog(),
              // ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            appStrings.gameSettings,
            [
              _buildSwitchTile(
                icon: Icons.volume_up,
                title: appStrings.soundEffects,
                value: _soundEnabled,
                onChanged: (value) async {
                  setState(() => _soundEnabled = value);
                  await SoundService().setSoundEnabled(value);
                  if (value) {
                    SoundService().playButton();
                  }
                },
              ),
              _buildSwitchTile(
                icon: Icons.vibration,
                title: appStrings.vibration,
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() => _vibrationEnabled = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            appStrings.language,
            [
              _buildLanguageOption(
                'English',
                '🇬🇧',
                'en',
              ),
              _buildLanguageOption(
                'ខ្មែរ',
                '🇰🇭',
                'km',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            appStrings.about,
            [
              _buildInfoTile(
                icon: Icons.info_outline,
                title: appStrings.version,
                subtitle: '1.0.0',
              ),
              _buildInfoTile(
                icon: Icons.book_outlined,
                title: appStrings.gameRules,
                subtitle: 'Learn how to play Khmer Chess',
                onTap: () => _showGameRulesDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.templeGold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.templeGold),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.templeGold,
        activeTrackColor: AppColors.templeGold.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildLanguageOption(String title, String flag, String languageCode) {
    final isSelected = _selectedLanguage == languageCode;
    
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.templeGold)
          : null,
      onTap: () async {
        setState(() => _selectedLanguage = languageCode);
        await appStrings.setLanguage(languageCode);
        if (_soundEnabled) {
          SoundService().playButton();
        }
        // Rebuild the whole screen to apply new language
        setState(() {});
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.templeGold),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
          : null,
      onTap: onTap,
    );
  }

  void _showGameRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(appStrings.gameRules),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRuleItem('ស្ដេច (King)', 'Moves 1 square in any direction'),
              _buildRuleItem('នាង (Maiden)', 'Moves 1 square diagonally (4 directions)'),
              _buildRuleItem('គោល (Elephant)', 'Moves 1 square diagonally (4 directions) or 1 square forward'),
              _buildRuleItem('សេះ (Horse)', 'Moves in an L-shape (can jump)'),
              _buildRuleItem('ទូក (Boat)', 'Moves any number of squares horizontally or vertically'),
              _buildRuleItem('ត្រី (Fish)', 'Moves 1 square forward, captures diagonally'),
              const Divider(color: AppColors.surfaceLight),
              const Text(
                'Special: Fish promotes to Maiden when reaching rank 5',
                style: TextStyle(
                  color: AppColors.templeGold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String piece, String rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              piece,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              rule,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _user?.name ?? '');
    final emailController = TextEditingController(text: _user?.email ?? '');
    final phoneController = TextEditingController(text: _user?.phoneNumber ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppColors.templeGold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.person, color: AppColors.templeGold),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.surfaceLight),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.templeGold),
                  ),
                ),
              ),
              // const SizedBox(height: 16),
              // TextField(
              //   controller: emailController,
              //   keyboardType: TextInputType.emailAddress,
              //   style: const TextStyle(color: AppColors.textPrimary),
              //   decoration: const InputDecoration(
              //     labelText: 'Email',
              //     labelStyle: TextStyle(color: AppColors.textSecondary),
              //     prefixIcon: Icon(Icons.email_outlined, color: AppColors.templeGold),
              //     enabledBorder: UnderlineInputBorder(
              //       borderSide: BorderSide(color: AppColors.surfaceLight),
              //     ),
              //     focusedBorder: UnderlineInputBorder(
              //       borderSide: BorderSide(color: AppColors.templeGold),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),
              // TextField(
              //   controller: phoneController,
              //   keyboardType: TextInputType.phone,
              //   style: const TextStyle(color: AppColors.textPrimary),
              //   decoration: const InputDecoration(
              //     labelText: 'Phone Number',
              //     labelStyle: TextStyle(color: AppColors.textSecondary),
              //     prefixIcon: Icon(Icons.phone_outlined, color: AppColors.templeGold),
              //     enabledBorder: UnderlineInputBorder(
              //       borderSide: BorderSide(color: AppColors.surfaceLight),
              //     ),
              //     focusedBorder: UnderlineInputBorder(
              //       borderSide: BorderSide(color: AppColors.templeGold),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _userRepository.updateProfile(
                name: nameController.text.isNotEmpty ? nameController.text : null,
                email: emailController.text.isNotEmpty ? emailController.text : null,
                phoneNumber: phoneController.text.isNotEmpty ? phoneController.text : null,
              );
              
              // Reload user data
              final updatedUser = await _userRepository.getUser();
              setState(() => _user = updatedUser);
              
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.templeGold,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
