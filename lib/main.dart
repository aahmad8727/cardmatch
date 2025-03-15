import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// MAIN ENTRY POINT
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: CardMatchingApp(),
    ),
  );
}

/// ROOT APP
class CardMatchingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Card Matching Game', home: GameScreen());
  }
}

/// MODEL FOR EACH CARD
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

class GameProvider extends ChangeNotifier {
  List<GameCard> _cards = [];
  GameCard? _firstSelected;
  bool _waiting = false;

  // Timer and scoring
  DateTime? _startTime;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _score = 0;
  bool _gameFinished = false;

  GameProvider() {
    _initializeCards();
  }

  // Getters
  List<GameCard> get cards => _cards;
  int get elapsedSeconds => _elapsedSeconds;
  int get score => _score;
  bool get gameFinished => _gameFinished;

  void _initializeCards() {
    print("Initializing cards...");
    List<String> contents = List.generate(8, (index) => (index + 1).toString());
    List<GameCard> tempCards = [];
    int id = 0;
    for (var content in contents) {
      tempCards.add(GameCard(id: id++, content: content));
      tempCards.add(GameCard(id: id++, content: content));
    }
    tempCards.shuffle(Random());
    _cards = tempCards;

    // Reset state
    _firstSelected = null;
    _waiting = false;
    _elapsedSeconds = 0;
    _score = 0;
    _gameFinished = false;
    _stopTimer();
    _startTime = null;

    notifyListeners();
  }

  /// START THE TIMER WHEN THE FIRST CARD IS FLIPPED
  void _startTimer() {
    print("Starting timer...");
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      // Debug print for timer
      print("Timer tick: $_elapsedSeconds");
      notifyListeners();
    });
  }

  /// STOP THE TIMER (CALLED WHEN THE GAME IS WON)
  void _stopTimer() {
    print("Stopping timer...");
    _timer?.cancel();
  }

  /// RESET THE GAME (SHUFFLE CARDS, RESET SCORE/TIMER)
  void resetGame() {
    print("Resetting game...");
    _initializeCards();
  }

  /// FLIP A CARD WHEN TAPPED
  void flipCard(GameCard card) {
    // If we are waiting for a mismatch animation, or the card is already face-up, do nothing
    if (_waiting || card.isFaceUp || card.isMatched) {
      print(
        "flipCard: Doing nothing because waiting: $_waiting, isFaceUp: ${card.isFaceUp}, isMatched: ${card.isMatched}",
      );
      return;
    }

    // Start timer if it's the first move
    if (_startTime == null) {
      _startTimer();
    }

    print("Flipping card id: ${card.id}, content: ${card.content}");
    card.isFaceUp = true;
    notifyListeners();

    // If this is the first selected card, just store it
    if (_firstSelected == null) {
      print("First card selected: id: ${card.id}, content: ${card.content}");
      _firstSelected = card;
    } else {
      // We have two flipped cards now
      _waiting = true;
      print("Second card selected: id: ${card.id}, content: ${card.content}");
      // Check for match
      if (_firstSelected!.content == card.content) {
        // It's a match
        print("Cards match! Awarding +10 points.");
        card.isMatched = true;
        _firstSelected!.isMatched = true;
        _score += 10; // Award points
        _firstSelected = null;
        _waiting = false;
        notifyListeners();
        _checkWinCondition();
      } else {
        // Not a match
        print("Cards do not match! Deducting 5 points.");
        _score = max(_score - 5, 0); // Deduct points
        // Flip back after a short delay
        Timer(const Duration(seconds: 1), () {
          print("Flipping cards back...");
          card.isFaceUp = false;
          _firstSelected!.isFaceUp = false;
          _firstSelected = null;
          _waiting = false;
          notifyListeners();
        });
      }
    }
  }

  void _checkWinCondition() {
    final allMatched = _cards.every((card) => card.isMatched);
    print("Checking win condition: allMatched=$allMatched");
    if (allMatched) {
      print("All cards matched, stopping timer, setting gameFinished=true");
      _stopTimer();
      _gameFinished = true;
      notifyListeners();
    }
  }
}

/// MAIN GAME SCREEN
class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // If game finished, show win dialog
        if (gameProvider.gameFinished) {
          // Delay a bit to allow flip animation to complete
          Future.delayed(const Duration(milliseconds: 300), () {
            _showWinDialog(
              context,
              gameProvider.elapsedSeconds,
              gameProvider.score,
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Card Matching Game'),
            actions: [
              // Timer display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text("Time: ${gameProvider.elapsedSeconds}s"),
                ),
              ),
              // Score display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(child: Text("Score: ${gameProvider.score}")),
              ),
              // Restart button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  gameProvider.resetGame();
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: gameProvider.cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 columns
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

  void _showWinDialog(BuildContext context, int elapsedSeconds, int score) {
    print("Showing win dialog: time=$elapsedSeconds, score=$score");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text("You Win!"),
            content: Text("Time: ${elapsedSeconds}s\nScore: $score"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Provider.of<GameProvider>(context, listen: false).resetGame();
                },
                child: const Text("Play Again"),
              ),
            ],
          ),
    );
  }
}

class CardWidget extends StatefulWidget {
  final GameCard card;
  const CardWidget({Key? key, required this.card}) : super(key: key);

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
    // Setup animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    if (widget.card.isFaceUp) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        print(
          "Card tapped: id=${widget.card.id}, faceUp=${widget.card.isFaceUp}",
        );
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
                          style: const TextStyle(
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
