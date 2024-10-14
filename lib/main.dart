import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const CardMatchingGame(),
    ),
  );
}

class CardMatchingGame extends StatelessWidget {
  const CardMatchingGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Card Matching Game'),
          backgroundColor: Colors.teal, // Custom AppBar color
        ),
        body: Column(
          children: [
            const TimerAndScoreDisplay(),
            const SizedBox(
                height: 10), // Add some space between the timer and grid
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.all(16.0), // Add padding around the grid
                child: CardGrid(),
              ),
            ),
            const SizedBox(
                height: 10), // Add some space between grid and button
            const RestartButton(),
            const SizedBox(height: 20), // Add space at the bottom
          ],
        ),
      ),
    );
  }
}

// Timer and Score Widget
class TimerAndScoreDisplay extends StatelessWidget {
  const TimerAndScoreDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Time: ${gameState.timeElapsed} s',
              style: const TextStyle(fontSize: 20)),
          Text('Score: ${gameState.score}',
              style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

// 3x4 Grid of Cards
class CardGrid extends StatelessWidget {
  const CardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3x4 grid
        crossAxisSpacing: 10, // Space between columns
        mainAxisSpacing: 10, // Space between rows
      ),
      itemCount: gameState.cards.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            gameState.onCardTapped(index);
          },
          child: CardWidget(card: gameState.cards[index]),
        );
      },
    );
  }
}

// Card Widget with Flipping Animation and Better UI
class CardWidget extends StatelessWidget {
  final CardModel card;

  const CardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration:
          const Duration(milliseconds: 500), // Animation duration for flipping
      transitionBuilder: (child, animation) {
        return RotationYTransition(
            turns: animation, child: child); // Flip the card horizontally
      },
      child: card.isFaceUp
          ? Container(
              key: ValueKey(card.frontDesign),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), // Rounded corners
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: Offset(2, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                    'assets/${card.frontDesign}.jpg'), // Show front design
              ),
            )
          : Container(
              key: const ValueKey('back'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), // Rounded corners
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: Offset(2, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/back11.jpg'), // Show back design
              ),
            ),
    );
  }
}

// RotationYTransition class to handle horizontal flip animation
class RotationYTransition extends AnimatedWidget {
  final Widget child;
  RotationYTransition({required Animation<double> turns, required this.child})
      : super(listenable: turns);

  @override
  Widget build(BuildContext context) {
    final Animation<double> turns = listenable as Animation<double>;
    final Matrix4 transform = Matrix4.rotationY(turns.value * 3.1416);
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: turns.value > 0.5 ? child : child, // flip back to front
    );
  }
}

// Card Model
class CardModel {
  final String frontDesign;
  bool isFaceUp;

  CardModel({required this.frontDesign, this.isFaceUp = false});
}

// Restart Button Widget with Better UI
class RestartButton extends StatelessWidget {
  const RestartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: false);
    return ElevatedButton(
      onPressed: () {
        gameState.restartGame();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal, // Custom button color
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        textStyle: const TextStyle(fontSize: 18),
      ),
      child: const Text('Restart Game'),
    );
  }
}

// GameState Class to Manage Game Logic
class GameState extends ChangeNotifier {
  List<CardModel> cards = [];
  Timer? gameTimer;
  int timeElapsed = 0;
  int score = 0;
  List<int> selectedIndices = [];

  GameState() {
    restartGame();
  }

  // Initialize and Shuffle Cards
  void restartGame() {
    cards = List.generate(
        6, (index) => CardModel(frontDesign: 'images${(index % 6) + 1}'))
      ..addAll(List.generate(
          6, (index) => CardModel(frontDesign: 'images${(index % 6) + 1}')));
    cards.shuffle(); // Shuffle cards to randomize the grid
    timeElapsed = 0;
    score = 0;
    selectedIndices.clear();
    _startTimer();
    notifyListeners();
  }

  // Handle Card Tapping
  void onCardTapped(int index) {
    if (cards[index].isFaceUp || selectedIndices.length == 2) return;

    // Flip the tapped card face-up
    cards[index].isFaceUp = true;
    selectedIndices.add(index);

    if (selectedIndices.length == 2) {
      // Two cards are now face-up, check if they match
      if (cards[selectedIndices[0]].frontDesign ==
          cards[selectedIndices[1]].frontDesign) {
        // Cards match, keep them face-up
        score += 10;
        selectedIndices.clear();
      } else {
        // Cards do not match, flip them back after a delay
        Future.delayed(const Duration(seconds: 1), () {
          cards[selectedIndices[0]].isFaceUp = false;
          cards[selectedIndices[1]].isFaceUp = false;
          selectedIndices.clear();
          notifyListeners();
        });
        score -= 2;
      }
    }

    notifyListeners();
  }

  // Start Timer
  void _startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeElapsed += 1;
      notifyListeners();
    });
  }
}
