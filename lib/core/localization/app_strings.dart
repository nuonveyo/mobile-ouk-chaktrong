import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App localization strings for Khmer and English
class AppStrings {
  static final AppStrings _instance = AppStrings._internal();
  factory AppStrings() => _instance;
  AppStrings._internal();

  Locale _locale = const Locale('en');
  bool _initialized = false;

  Locale get locale => _locale;
  bool get isKhmer => _locale.languageCode == 'km';
  bool get isEnglish => _locale.languageCode == 'en';

  /// Initialize with saved preference
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    _locale = Locale(langCode);
    _initialized = true;
  }

  /// Change language
  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }

  // ============ APP STRINGS ============

  // App title
  String get appTitle => _get('Ouk Chaktrong', 'អុកចត្រង្គ');

  // Home screen
  String get playVsAi => _get('Play vs AI', 'លេងជាមួយ AI');
  String get local2Players => _get('Local 2 Players', 'លេង ២ នាក់');
  String get onlineMatch => _get('Online Match', 'លេង Online');
  String get settings => _get('Settings', 'ការកំណត់');

  // AI Difficulty
  String get selectDifficulty => _get('Select Difficulty', 'ជ្រើសរើសកម្រិត');
  String get easy => _get('Easy', 'ងាយស្រួល');
  String get medium => _get('Medium', 'មធ្យម');
  String get hard => _get('Hard', 'លំបាក');

  // Game screen
  String get yourTurn => _get('Your turn', 'វេនអ្នក');
  String get waiting => _get('Waiting...', 'រង់ចាំ...');
  String get check => _get('CHECK', 'រុក');
  String get undo => _get('Undo', 'ត្រឡប់');
  String get resign => _get('Resign', 'ចាញ់');
  String get draw => _get('Draw', 'ស្មើ');
  String get newGame => _get('New Game', 'ល្បែងថ្មី');
  String get playAgain => _get('Play Again', 'លេងម្ដងទៀត');
  String get exit => _get('Exit', 'ចេញ');

  // Game results
  String get whiteWins => _get('White Wins!', 'ស ឈ្នះ!');
  String get goldWins => _get('Gold Wins!', 'មាស ឈ្នះ!');
  String get drawResult => _get('Draw', 'ស្មើ');
  String get congratulations => _get('Congratulations!', 'សូមអបអរសាទរ!');

  // Dialogs
  String get leaveGame => _get('Leave Game?', 'ចាកចេញពីល្បែង?');
  String get leaveGameMessage => _get('Your progress will be lost.', 'ដំណើរការនឹងត្រូវបាត់បង់។');
  String get resignGame => _get('Resign?', 'ចាញ់?');
  String get resignGameMessage => _get('Are you sure you want to resign?', 'តើអ្នកចង់ចាញ់មែនទេ?');
  String get cancel => _get('Cancel', 'បោះបង់');
  String get leave => _get('Leave', 'ចាកចេញ');
  String get confirm => _get('Confirm', 'បញ្ជាក់');

  // Settings screen
  String get gameSettings => _get('Game Settings', 'ការកំណត់ល្បែង');
  String get soundEffects => _get('Sound Effects', 'សំឡេង');
  String get vibration => _get('Vibration', 'ញ័រ');
  String get language => _get('Language', 'ភាសា');
  String get english => _get('English', 'អង់គ្លេស');
  String get khmer => _get('Khmer', 'ខ្មែរ');
  String get about => _get('About', 'អំពី');
  String get version => _get('Version', 'ជំនាន់');
  String get gameRules => _get('Game Rules', 'ច្បាប់ល្បែង');

  // Online lobby
  String get onlineLobby => _get('Online Lobby', 'បន្ទប់ Online');
  String get createRoom => _get('Create Room', 'បង្កើតបន្ទប់');
  String get availableRooms => _get('Available Rooms', 'បន្ទប់ទំនេរ');
  String get noRoomsAvailable => _get('No rooms available', 'គ្មានបន្ទប់ទេ');
  String get createRoomToStart => _get('Create a room to start playing!', 'បង្កើតបន្ទប់ដើម្បីចាប់ផ្តើមលេង!');
  String get waitingForOpponent => _get('Waiting for opponent...', 'រង់ចាំគូប្រកួត...');
  String get join => _get('Join', 'ចូល');
  String get timeControl => _get('Time Control', 'ពេលវេលា');

  // Pieces (for accessibility)
  String get king => _get('King', 'ស្ដេច');
  String get maiden => _get('Maiden', 'នាង');
  String get elephant => _get('Elephant', 'គោល');
  String get horse => _get('Horse', 'សេះ');
  String get boat => _get('Boat', 'ទូក');
  String get fish => _get('Fish', 'ត្រី');

  // Helper to get string based on locale
  String _get(String en, String km) {
    return isKhmer ? km : en;
  }
}

/// Global instance for easy access
final appStrings = AppStrings();
