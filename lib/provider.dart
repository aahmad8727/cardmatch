import 'package:flutter/material.dart';
import 'provider.dart';
import 'dart:math';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: CardMatchingApp(),
    ),
  );
}

class CardMatchingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Card Matching Game', home: GameScreen());
  }
}

/// Data model for each game card.
class GameCard {
  final int id;
  final String content; // This can be text or an image asset.
  bool isFaceUp;
  bool isMatched;

  GameCard({
    required this.id,
    required this.content,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

/// Provider to manage the game state.
class GameProvider extends ChangeNotifier {
  List<GameCard> _cards = [];

  GameProvider() {
    _initializeCards();
  }

  List<GameCard> get cards => _cards;

  /// Initializes the card list with pairs and shuffles them.
  void _initializeCards() {
    // For a 4x4 grid, we need 8 pairs.
    List<String> contents = List.generate(8, (index) => (index + 1).toString());
    List<GameCard> tempCards = [];
    int id = 0;
    for (var content in contents) {
      tempCards.add(GameCard(id: id++, content: content));
      tempCards.add(GameCard(id: id++, content: content));
    }
    tempCards.shuffle(Random());
    _cards = tempCards;
    notifyListeners();
  }

  /// Resets the game state.
  void resetGame() {
    _initializeCards();
  }

  // Future methods for flipping cards and checking for matches can be added here.
}

/// Main game screen displaying a grid of cards.
class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Card Matching Game'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              gameProvider.resetGame();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: gameProvider.cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4 columns for a 4x4 grid.
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemBuilder: (context, index) {
            final card = gameProvider.cards[index];
            return GestureDetector(
              onTap: () {
                // For demonstration, toggle the card's face.
                card.isFaceUp = !card.isFaceUp;
                gameProvider.notifyListeners();
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      card.isFaceUp || card.isMatched
                          ? Colors.orange
                          : Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child:
                      card.isFaceUp || card.isMatched
                          ? Text(
                            card.content,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : Container(), // When face down, you might show a back design.
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
