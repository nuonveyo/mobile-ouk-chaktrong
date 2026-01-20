import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../models/models.dart';
import 'test_game_screen.dart';

/// Test scenarios screen for debugging counting rules
class TestScenariosScreen extends StatelessWidget {
  const TestScenariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Test Scenarios'),
        backgroundColor: AppColors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Board\'s Honor Counting'),
          _buildScenarioCard(
            context,
            title: 'White has 3 pieces',
            description: 'White: King + 2 Boats\nGold: King + Queen + 2 Boats',
            scenario: TestScenario.whiteBoardHonor3Pieces,
          ),
          _buildScenarioCard(
            context,
            title: 'White has 2 pieces',
            description: 'White: King + 1 Boat\nGold: King + Queen + 2 Boats',
            scenario: TestScenario.whiteBoardHonor2Pieces,
          ),
          _buildScenarioCard(
            context,
            title: 'Gold has 3 pieces',
            description: 'White: King + Queen + 2 Boats\nGold: King + 2 Boats',
            scenario: TestScenario.goldBoardHonor3Pieces,
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Piece\'s Honor Counting'),
          _buildScenarioCard(
            context,
            title: 'White has only King (2 Boats)',
            description: 'White: King only\nGold: King + 2 Boats\nLimit: 8',
            scenario: TestScenario.whitePieceHonor2Boats,
          ),
          _buildScenarioCard(
            context,
            title: 'White has only King (1 Boat)',
            description: 'White: King only\nGold: King + 1 Boat\nLimit: 16',
            scenario: TestScenario.whitePieceHonor1Boat,
          ),
          _buildScenarioCard(
            context,
            title: 'White has only King (2 Elephants)',
            description: 'White: King only\nGold: King + 2 Elephants\nLimit: 22',
            scenario: TestScenario.whitePieceHonor2Elephants,
          ),
          _buildScenarioCard(
            context,
            title: 'White has only King (2 Horses)',
            description: 'White: King only\nGold: King + 2 Horses\nLimit: 32',
            scenario: TestScenario.whitePieceHonor2Horses,
          ),
          _buildScenarioCard(
            context,
            title: 'White has only King (1 Maiden)',
            description: 'White: King only\nGold: King + 1 Maiden\nLimit: 64',
            scenario: TestScenario.whitePieceHonor1Maiden,
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Edge Cases'),
          _buildScenarioCard(
            context,
            title: 'Both can count (3 pieces each)',
            description: 'White: King + 2 pieces\nGold: King + 2 pieces',
            scenario: TestScenario.bothCanCount,
          ),
          _buildScenarioCard(
            context,
            title: 'Near promotion (Fish on 4th rank)',
            description: 'White: King + Fish near promotion\nGold: King + Queen',
            scenario: TestScenario.nearPromotion,
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Arb (Boat Indirect Attack)'),
          _buildScenarioCard(
            context,
            title: 'Arb - Gold King Trapped',
            description: 'White Boat on same file as Gold King\nGold has NO legal moves\nResult: Draw',
            scenario: TestScenario.arbGoldTrapped,
          ),
          _buildScenarioCard(
            context,
            title: 'Arb - White King Trapped',
            description: 'Gold Boat on same rank as White King\nWhite has NO legal moves\nResult: Draw',
            scenario: TestScenario.arbWhiteTrapped,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.templeGold,
        ),
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context, {
    required String title,
    required String description,
    required TestScenario scenario,
  }) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.play_arrow, color: AppColors.templeGold),
        onTap: () => _navigateToScenario(context, scenario),
      ),
    );
  }

  void _navigateToScenario(BuildContext context, TestScenario scenario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestGameScreen(scenario: scenario),
      ),
    );
  }
}

/// Test scenarios enum
enum TestScenario {
  whiteBoardHonor3Pieces,
  whiteBoardHonor2Pieces,
  goldBoardHonor3Pieces,
  whitePieceHonor2Boats,
  whitePieceHonor1Boat,
  whitePieceHonor2Elephants,
  whitePieceHonor2Horses,
  whitePieceHonor1Maiden,
  bothCanCount,
  nearPromotion,
  arbGoldTrapped,
  arbWhiteTrapped,
}

/// Get preset board state for a scenario
BoardState getScenarioBoardState(TestScenario scenario) {
  switch (scenario) {
    case TestScenario.whiteBoardHonor3Pieces:
      // White: King + 2 Boats, Gold: King + Queen + 2 Boats
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(0, 0): const Piece(type: PieceType.boat, color: PlayerColor.white),
        const Position(0, 7): const Piece(type: PieceType.boat, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 3): const Piece(type: PieceType.maiden, color: PlayerColor.gold),
        const Position(7, 0): const Piece(type: PieceType.boat, color: PlayerColor.gold),
        const Position(7, 7): const Piece(type: PieceType.boat, color: PlayerColor.gold),
      });

    case TestScenario.whiteBoardHonor2Pieces:
      // White: King + 1 Boat, Gold: King + Queen + 2 Boats
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(0, 0): const Piece(type: PieceType.boat, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 3): const Piece(type: PieceType.maiden, color: PlayerColor.gold),
        const Position(7, 0): const Piece(type: PieceType.boat, color: PlayerColor.gold),
        const Position(7, 7): const Piece(type: PieceType.boat, color: PlayerColor.gold),
      });

    case TestScenario.goldBoardHonor3Pieces:
      // White: King + Queen + 2 Boats, Gold: King + 2 Boats
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(0, 3): const Piece(type: PieceType.maiden, color: PlayerColor.white),
        const Position(0, 0): const Piece(type: PieceType.boat, color: PlayerColor.white),
        const Position(0, 7): const Piece(type: PieceType.boat, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 0): const Piece(type: PieceType.boat, color: PlayerColor.gold),
        const Position(7, 7): const Piece(type: PieceType.boat, color: PlayerColor.gold),
      });

    case TestScenario.whitePieceHonor2Boats:
      // White: King only, Gold: King + 2 Boats (Limit: 8)
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 0): const Piece(type: PieceType.boat, color: PlayerColor.gold),
        const Position(7, 7): const Piece(type: PieceType.boat, color: PlayerColor.gold),
      });

    case TestScenario.whitePieceHonor1Boat:
      // White: King only, Gold: King + 1 Boat (Limit: 16)
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 0): const Piece(type: PieceType.boat, color: PlayerColor.gold),
      });

    case TestScenario.whitePieceHonor2Elephants:
      // White: King only, Gold: King + 2 Elephants (Limit: 22)
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 2): const Piece(type: PieceType.elephant, color: PlayerColor.gold),
        const Position(7, 5): const Piece(type: PieceType.elephant, color: PlayerColor.gold),
      });

    case TestScenario.whitePieceHonor2Horses:
      // White: King only, Gold: King + 2 Horses (Limit: 32)
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 1): const Piece(type: PieceType.horse, color: PlayerColor.gold),
        const Position(7, 6): const Piece(type: PieceType.horse, color: PlayerColor.gold),
      });

    case TestScenario.whitePieceHonor1Maiden:
      // White: King only, Gold: King + 1 Maiden (Limit: 64)
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 3): const Piece(type: PieceType.maiden, color: PlayerColor.gold),
      });

    case TestScenario.bothCanCount:
      // Both have 3 pieces
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(0, 0): const Piece(type: PieceType.boat, color: PlayerColor.white),
        const Position(0, 7): const Piece(type: PieceType.boat, color: PlayerColor.white),
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 0): const Piece(type: PieceType.boat, color: PlayerColor.gold),
        const Position(7, 7): const Piece(type: PieceType.boat, color: PlayerColor.gold),
      });

    case TestScenario.nearPromotion:
      // White fish near promotion
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(4, 3): const Piece(type: PieceType.fish, color: PlayerColor.white), // Near promotion row 5
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
        const Position(7, 3): const Piece(type: PieceType.maiden, color: PlayerColor.gold),
      });

    case TestScenario.arbGoldTrapped:
      // Arb scenario: Boat on same file as King, King trapped in corner
      // Gold King at h8, White Boat at h1 (same file), Gold King can't move
      // White pieces block all escape squares
      return _createBoard({
        const Position(0, 4): const Piece(type: PieceType.king, color: PlayerColor.white),
        const Position(0, 7): const Piece(type: PieceType.boat, color: PlayerColor.white), // h1 - same file as Gold King
        const Position(5, 6): const Piece(type: PieceType.boat, color: PlayerColor.white), // Blocks g6
        const Position(6, 7): const Piece(type: PieceType.maiden, color: PlayerColor.white), // Controls g7, h7
        const Position(7, 7): const Piece(type: PieceType.king, color: PlayerColor.gold), // h8 - trapped!
      });

    case TestScenario.arbWhiteTrapped:
      // Arb scenario: Boat on same rank as King, King trapped
      // White King at a1, Gold Boat at h1 (same rank), White King can't move
      return _createBoard({
        const Position(0, 0): const Piece(type: PieceType.king, color: PlayerColor.white), // a1 - trapped!
        const Position(0, 7): const Piece(type: PieceType.boat, color: PlayerColor.gold), // h1 - same rank
        const Position(1, 0): const Piece(type: PieceType.boat, color: PlayerColor.gold), // a2 - blocks escape
        const Position(1, 1): const Piece(type: PieceType.maiden, color: PlayerColor.gold), // b2 - controls a1, b1
        const Position(7, 4): const Piece(type: PieceType.king, color: PlayerColor.gold),
      });
  }
}

BoardState _createBoard(Map<Position, Piece> pieces) {
  // Start with empty board
  final emptyBoard = BoardState.empty();
  
  // Apply each piece
  BoardState result = emptyBoard;
  for (final entry in pieces.entries) {
    result = result.setPiece(entry.key, entry.value);
  }
  
  return result;
}
