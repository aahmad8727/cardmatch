import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'provider.dart';

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

/// Data model for each card.
class GameCard {
  final int id;
  final String content;
  bool isFaceUp;
  bool isMatched;

  GameCard({
    required this.id,
    required this.content,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

/// Provider to manage game state, timer, score, and game logic.
class GameProvider extends ChangeNotifier {
  List<GameCard> _cards = [];
  GameCard? _firstSelected;
  bool _waiting = false;

  // Timer and scoring system.
  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _score = 0;
  bool _gameFinished = false;

  GameProvider() {
    _initializeCards();
  }

  List<GameCard> get cards => _cards;
  int get elapsedSeconds => _elapsedSeconds;
  int get score => _score;
  bool get gameFinished => _gameFinished;

  /// Initializes card pairs and shuffles them.
  void _initializeCards() {
    List<String> contents = List.generate(8, (index) => (index + 1).toString());
    List<GameCard> tempCards = [];
    int id = 0;
    for (var content in contents) {
      tempCards.add(GameCard(id: id++, content: content));
      tempCards.add(GameCard(id: id++, content: content));
    }
    tempCards.shuffle(Random());
    _cards = tempCards;

    // Reset game variables.
    _firstSelected = null;
    _waiting = false;
    _elapsedSeconds = 0;
    _score = 0;
    _gameFinished = false;
    _stopTimer();
    _startTime = null;

    notifyListeners();
  }

  /// Starts the game timer.
  void _startTimer() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  /// Stops the game timer.
  void _stopTimer() {
    _timer?.cancel();
  }

  /// Resets the game.
  void resetGame() {
    _initializeCards();
  }

  /// Called when a card is tapped.
  void flipCard(GameCard card) {
    // Do nothing if waiting
    if (_waiting || card.isFaceUp || card.isMatched) return;

    // Start timer when first card is flipped.
    if (_startTime == null) {
      _startTimer();
    }

    card.isFaceUp = true;
    notifyListeners();

    if (_firstSelected == null) {
      _firstSelected = card;
    } else {
      // Two cards are flipped
      _waiting = true;
      // Check for match
      if (_firstSelected!.content == card.content) {
        //mark both as matched.
        card.isMatched = true;
        _firstSelected!.isMatched = true;
        _score += 10; // Award points
        _firstSelected = null;
        _waiting = false;
        notifyListeners();
        _checkWinCondition();
      } else {
        _score = max(_score - 5, 0);
        // After a delay, flip both cards back.
        Timer(Duration(seconds: 1), () {
          card.isFaceUp = false;
          _firstSelected!.isFaceUp = false;
          _firstSelected = null;
          _waiting = false;
          notifyListeners();
        });
      }
    }
  }

  /// Checks if all cards have been matched.
  void _checkWinCondition() {
    if (_cards.every((card) => card.isMatched)) {
      _stopTimer();
      _gameFinished = true;
      notifyListeners();
    }
  }
}

/// Displaying timer, score, and grid of cards
class GameScreen extends StatelessWidget {
  void _showWinDialog(BuildContext context, int elapsedSeconds, int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: Text("You Win!"),
            content: Text("Time: ${elapsedSeconds}s\nScore: $score"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Provider.of<GameProvider>(context, listen: false).resetGame();
                },
                child: Text("Play Again"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // Show win dialog if game finished.
        if (gameProvider.gameFinished) {
          Future.delayed(Duration(milliseconds: 300), () {
            _showWinDialog(
              context,
              gameProvider.elapsedSeconds,
              gameProvider.score,
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Card Matching Game'),
            actions: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text("Time: ${gameProvider.elapsedSeconds}s"),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(child: Text("Score: ${gameProvider.score}")),
              ),
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
                return CardWidget(card: card);
              },
            ),
          ),
        );
      },
    );
  }
}

/// Widget representing an individual card with a flip animation.
class CardWidget extends StatefulWidget {
  final GameCard card;
  CardWidget({required this.card});

  @override
  _CardWidgetState createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    // If the card is already face up at the start, show it.
    if (widget.card.isFaceUp) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when card face state changes.
    if (widget.card.isFaceUp != oldWidget.card.isFaceUp) {
      if (widget.card.isFaceUp) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Provider.of<GameProvider>(context, listen: false).flipCard(widget.card);
      },
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isFront = _flipAnimation.value >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi * _flipAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                color:
                    widget.card.isFaceUp || widget.card.isMatched
                        ? Colors.orange
                        : Colors.blueAccent,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child:
                    isFront
                        ? Text(
                          widget.card.content,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : Container(),
              ),
            ),
          );
        },
      ),
    );
  }
}
