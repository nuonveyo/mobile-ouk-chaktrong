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

  Future<String> getLanguage() async{
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    return langCode;
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
  String get challengeComputer => _get('Challenge the computer', 'ប្រកួតជាមួយកុំព្យូទ័រ');
  String get local2Players => _get('Local 2 Players', 'លេង ២ នាក់');
  String get playWithFriend => _get('Play with a friend', 'លេងជាមួយមិត្តភក្តិ');
  String get onlineMatch => _get('Online Match', 'លេង Online');
  String get playWorldwide => _get('Play worldwide', 'លេងទូទាំងពិភពលោក');
  String get settings => _get('Settings', 'ការកំណត់');
  String get testScenarios => _get('Test Scenarios', 'សាកល្បង');
  String get home => _get('Home', 'ដើម');
  String get ranks => _get('Ranks', 'ចំណាត់ថ្នាក់');
  String get test => _get('Test', 'សាកល្បង');

  // AI Difficulty
  String get selectDifficulty => _get('Select Difficulty', 'ជ្រើសរើសកម្រិត');
  String get easy => _get('Easy', 'ងាយស្រួល');
  String get perfectForBeginners => _get('Perfect for beginners', 'ល្អសម្រាប់អ្នកចាប់ផ្តើម');
  String get medium => _get('Medium', 'មធ្យម');
  String get balancedChallenge => _get('A balanced challenge', 'ការប្រកួតមានតុល្យភាព');
  String get hard => _get('Hard', 'លំបាក');
  String get forExperienced => _get('For experienced players', 'សម្រាប់អ្នកលេងមានបទពិសោធន៍');

  // Game screen
  String get yourTurn => _get('Your turn', 'វេនអ្នក');
  String get opponentTurn => _get("Opponent's Turn", 'វេនគូប្រកួត');
  String get waiting => _get('Waiting...', 'រង់ចាំ...');
  String get check => _get('CHECK', 'រុក');
  String get undo => _get('Undo', 'ត្រឡប់');
  String get resign => _get('Resign', 'ចាញ់');
  String get draw => _get('Draw', 'ស្មើ');
  String get newGame => _get('New Game', 'ល្បែងថ្មី');
  String get playAgain => _get('Play Again', 'លេងម្ដងទៀត');
  String get exit => _get('Exit', 'ចេញ');
  String get backToHome => _get('Back to Home', 'ត្រឡប់ទៅដើម');
  String get backToLobby => _get('Back to Lobby', 'ត្រឡប់ទៅបន្ទប់');

  // Game results
  String get checkmate => _get('Checkmate!', 'រុកឆ្មាត់!');
  String get youWin => _get('You Win!', 'អ្នកឈ្នះ!');
  String get gameOver => _get('Game Over', 'ល្បែងបញ្ចប់');
  String get whiteWins => _get('White Wins!', 'ស ឈ្នះ!');
  String get goldWins => _get('Gold Wins!', 'មាស ឈ្នះ!');
  String get drawResult => _get('Draw', 'ស្មើ');
  String get congratulations => _get('Congratulations!', 'សូមអបអរសាទរ!');
  String get opponentWins => _get('Your opponent wins.', 'គូប្រកួតឈ្នះ។');
  String get gameEndedInDraw => _get('The game ended in a draw.', 'ល្បែងស្មើគ្នា។');
  String pointsAwarded(int points) => _get('+$points coins!', '+$points កាក់!');

  // Counting rules
  String get drawCountingLimit => _get('Draw - Counting Limit Reached', 'ស្មើ - ដល់កំណត់រាប់');
  String get drawCountingRule => _get('Draw - Counting Rule', 'ស្មើ - ច្បាប់រាប់');
  String get boardHonor => _get("Board's Honor", 'កិត្តិយសក្តារ');
  String get pieceHonor => _get("Piece's Honor", 'កិត្តិយសគ្រាប់');
  String countingReachedLimit(String type, int limit) => 
      _get('$type counting reached $limit moves.\nThe game is a draw!', 
           'ការរាប់$type ដល់ $limit ជំហាន។\nល្បែងស្មើ!');
  String get countingPlayerCheckmate => 
      _get('The counting player achieved checkmate.\nBy the counting rules, this is a draw!',
           'អ្នកកំពុងរាប់បានរុកឆ្មាត់។\nតាមច្បាប់រាប់ នេះជាស្មើ!');

  // Dialogs
  String get leaveGame => _get('Leave Game?', 'ចាកចេញពីល្បែង?');
  String get leaveGameMessage => _get('Your progress will be lost.', 'ដំណើរការនឹងត្រូវបាត់បង់។');
  String get ifYouLeaveForfeit => _get('If you leave, you will forfeit.', 'បើចេញ អ្នកនឹងចាញ់។');
  String get resignGame => _get('Resign?', 'ចាញ់?');
  String get resignGameMessage => _get('Are you sure you want to resign?', 'តើអ្នកចង់ចាញ់មែនទេ?');
  String get cancel => _get('Cancel', 'បោះបង់');
  String get leave => _get('Leave', 'ចាកចេញ');
  String get stay => _get('Stay', 'នៅ');
  String get confirm => _get('Confirm', 'បញ្ជាក់');
  String get save => _get('Save', 'រក្សាទុក');
  String get close => _get('Close', 'បិទ');

  // Settings screen
  String get gameSettings => _get('Game Settings', 'ការកំណត់ល្បែង');
  String get soundEffects => _get('Sound Effects', 'សំឡេង');
  String get vibration => _get('Vibration', 'ញ័រ');
  String get movingPiece => _get('Moving a piece', 'ផ្លាស់ទីគ្រាប់');
  String get capturingPiece => _get('Capturing a piece', 'ស៊ីគ្រាប់');
  String get checkCheckmate => _get('Check / Checkmate', 'រុក / រុកឆ្មាត់');
  String get language => _get('Language', 'ភាសា');
  String get english => _get('English', 'អង់គ្លេស');
  String get khmer => _get('Khmer', 'ខ្មែរ');
  String get about => _get('About', 'អំពី');
  String get version => _get('Version', 'ជំនាន់');
  String get gameRules => _get('Game Rules', 'ច្បាប់ល្បែង');

  // Player profile
  String get playerStats => _get('Player Stats', 'ស្ថិតិអ្នកលេង');
  String get username => _get('Username', 'ឈ្មោះ');
  String get totalPoints => _get('Total Coins', 'កាក់សរុប');
  String get editProfile => _get('Edit Profile', 'កែប្រូហ្វាល');
  String get email => _get('Email', 'អ៊ីមែល');
  String get phoneNumber => _get('Phone Number', 'លេខទូរស័ព្ទ');
  String get notSet => _get('Not set', 'មិនទាន់កំណត់');
  String get loading => _get('Loading...', 'កំពុងផ្ទុក...');
  String get connecting => _get('Connecting...', 'កំពុងភ្ជាប់...');

  // Online lobby
  String get onlineLobby => _get('Online Lobby', 'បន្ទប់ Online');
  String get onlineGame => _get('Online Game', 'ល្បែង Online');
  String get createRoom => _get('Create Room', 'បង្កើតបន្ទប់');
  String get createGameRoom => _get('Create Game Room', 'បង្កើតបន្ទប់ល្បែង');
  String get create => _get('Create', 'បង្កើត');
  String get availableRooms => _get('Available Rooms', 'បន្ទប់ទំនេរ');
  String get noRoomsAvailable => _get('No rooms available', 'គ្មានបន្ទប់ទេ');
  String get createRoomToStart => _get('Create a room to start playing!', 'បង្កើតបន្ទប់ដើម្បីចាប់ផ្តើមលេង!');
  String get waitingForOpponent => _get('Waiting for opponent...', 'រង់ចាំគូប្រកួត...');
  String get join => _get('Join', 'ចូល');
  String get timeControl => _get('Time Control', 'ពេលវេលា');
  String get player => _get('Player', 'អ្នកលេង');
  String get room => _get('Room', 'បន្ទប់');
  String minFormat(int min) => _get('$min min', '$min នាទី');
  String get waitingOpponentShort => _get('Waiting for opponent', 'រង់ចាំគូប្រកួត');
  String get liveGames => _get('Live Games', 'ល្បែងផ្ទាល់');
  String get watch => _get('Watch', 'មើល');
  String get spectating => _get('Spectating', 'កំពុងមើល');
  String get spectators => _get('Spectators', 'អ្នកមើល');

  // Pieces (for accessibility and rules)
  String get king => _get('King', 'ស្ដេច');
  String get maiden => _get('Maiden', 'នាង');
  String get elephant => _get('Elephant', 'គោល');
  String get horse => _get('Horse', 'សេះ');
  String get boat => _get('Boat', 'ទូក');
  String get fish => _get('Fish', 'ត្រី');

  // Piece rules
  String get kingRule => _get('Moves 1 square in any direction', 'ផ្លាស់ទី ១ ប្រឡោង រាល់ទិសដៅ');
  String get maidenRule => _get('Moves 1 square diagonally (4 directions)', 'ផ្លាស់ទី ១ ប្រឡោង ទ្រេត (៤ ទិស)');
  String get elephantRule => _get('Moves 1 square diagonally (4 directions) or 1 square forward', 'ផ្លាស់ទី ១ ប្រឡោង ទ្រេត ឬ ១ ប្រឡោង មុខ');
  String get horseRule => _get('Moves in an L-shape (can jump)', 'ផ្លាស់ទីជារូប L (អាចលោត)');
  String get boatRule => _get('Moves any number of squares horizontally or vertically', 'ផ្លាស់ទីច្រើនប្រឡោង ផ្ដេក ឬ បញ្ឈរ');
  String get fishRule => _get('Moves 1 square forward, captures diagonally', 'ផ្លាស់ទី ១ ប្រឡោង មុខ ស៊ីទ្រេត');
  String get fishPromotion => _get('Special: Fish promotes to Maiden when reaching rank 5', 'ពិសេស: ត្រី បកក្លាយជា នាង នៅជួរទី ៥');

  // Draw offers
  String get offerDraw => _get('Offer Draw?', 'ស្នើសុំស្មើ?');
  String get offerDrawMessage => _get('Do you want to offer a draw to your opponent?', 'តើអ្នកចង់ស្នើសុំស្មើទៅគូប្រកួតឬ?');
  String get offerDrawButton => _get('Offer Draw', 'ស្នើសុំស្មើ');
  String get drawOffered => _get('Draw Offered', 'បានស្នើសុំស្មើ');
  String get drawOfferedMessage => _get('Your opponent offers a draw. Do you accept?', 'គូប្រកួតស្នើសុំស្មើ។ តើអ្នកយល់ព្រមឬ?');
  String get decline => _get('Decline', 'បដិសេធ');
  String get acceptDraw => _get('Accept Draw', 'យល់ព្រមស្មើ');

  // New game
  String get newGameQuestion => _get('New Game?', 'ល្បែងថ្មី?');
  String get newGameMessage => _get('Start a new game? Current progress will be lost.', 'ចាប់ផ្តើមល្បែងថ្មី? ដំណើរការនឹងបាត់បង់។');

  // Counting widget
  String get left => _get('left', 'នៅសល់');
  String get stop => _get('Stop', 'ឈប់');
  String get declareDraw => _get('Declare Draw', 'ប្រកាសស្មើ');
  String get startCounting => _get('Start Counting', 'ចាប់ផ្តើមរាប់');
  String boardHonorMoves(int moves) => _get("Count ($moves moves)", 'រាប់ ($moves ជំហាន)');

  // Misc
  String get updateNow => _get('UPDATE NOW', 'ធ្វើបច្ចុប្បន្នភាពឥឡូវនេះ');
  String get back => _get('Back', 'ត្រឡប់ក្រោយ');
  String get restart => _get('Restart', 'ចាប់ផ្តើមឡើងវិញ');

  // Join request flow
  String get joinRequest => _get('Join Request', 'សំណើចូលរួម');
  String guestWantsToJoin(String name) => _get('$name wants to join your game', '$name ចង់ចូលរួមការប្រកួតរបស់អ្នក');
  String get joinNow => _get('Join Now', 'ចូលរួមឥឡូវ');
  String get roomCancelled => _get('Room was cancelled by host', 'បន្ទប់ត្រូវបានលុបចោល');
  String get waitingForHostApproval => _get('Waiting for host approval...', 'កំពុងរង់ចាំការអនុម័ត...');
  String get playerWantsToJoin => _get('wants to join!', 'ចង់ចូលរួម!');
  String get accept => _get('Accept', 'ទទួល');
  String get you => _get('you', 'អ្នក');

  // Helper to get string based on locale
  String _get(String en, String km) {
    return isKhmer ? km : en;
  }
}

/// Global instance for easy access
final appStrings = AppStrings();
