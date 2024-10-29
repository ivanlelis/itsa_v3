import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package
import 'dart:math';
import 'dart:async'; // Import for the timer

void main() => runApp(MemoryGameWithChests());

class MemoryGameWithChests extends StatelessWidget {
  const MemoryGameWithChests({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  List<String> cards = [];
  List<bool> flipped = [];
  List<bool> matched = [];
  List<bool> unlockedChests = [
    false,
    false,
    false,
    false,
    false
  ]; // Track which chests are unlocked
  int firstSelectedIndex = -1;
  int secondSelectedIndex = -1;
  int points = 0;
  bool gameCompleted = false;
  int matchCount = 0; // To track successful matches
  int matchStreak = 0; // To track consecutive successful matches
  int remainingTime = 30; // Timer for the game
  late Timer gameTimer;

  final List<String> rewards = [
    "20% off voucher",
    "50% off voucher",
    "60% off voucher",
    "Another Chance!",
    "3 Free Deliveries!",
  ];

  // Animation controller for fireworks
  late AnimationController _fireworksController;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startGameTimer();

    // Initialize the animation controller here
    _fireworksController = AnimationController(
      duration:
          const Duration(seconds: 1), // Duration for the fireworks animation
      vsync: this, // Use this as the TickerProvider
    );
  }

  @override
  void dispose() {
    // Dispose of the animation controller when the widget is removed
    _fireworksController.dispose();
    gameTimer.cancel();
    super.dispose();
  }

  void _initializeGame() {
    List<String> cardValues = [
      '🍔',
      '🍕',
      '🍟',
      '🍣',
      '🍦',
      '🥗',
      '🍜',
      '🍤',
      '🍔',
      '🍕',
      '🍟',
      '🍣',
      '🍦',
      '🥗',
      '🍜',
      '🍤',
    ];
    cardValues.shuffle(Random());

    setState(() {
      cards = cardValues;
      flipped = List.filled(cards.length, false);
      matched = List.filled(cards.length, false);
      unlockedChests = [false, false, false, false, false];
      points = 0;
      gameCompleted = false;
      matchCount = 0;
      matchStreak = 0;
      remainingTime = 30;
    });
  }

  void _flipCard(int index) {
    // Prevent flipping if card is already matched or flipped
    if (matched[index] ||
        flipped[index] ||
        (firstSelectedIndex != -1 && secondSelectedIndex != -1)) {
      return;
    }

    setState(() {
      // Flip the card
      flipped[index] = true;

      // Check if it's the first or second card being selected
      if (firstSelectedIndex == -1) {
        firstSelectedIndex =
            index; // Store the index of the first selected card
      } else {
        secondSelectedIndex =
            index; // Store the index of the second selected card
        _checkMatch(); // Check if the two selected cards match
      }
    });
  }

  void _checkMatch() async {
    if (cards[firstSelectedIndex] == cards[secondSelectedIndex]) {
      setState(() {
        matched[firstSelectedIndex] = true;
        matched[secondSelectedIndex] = true;
        points += 10;
        matchCount++;
        matchStreak++;
        _updateChests();
        _resetSelection();

        if (matched.every((isMatched) => isMatched)) {
          _onGameCompleted();
        }
      });
    } else {
      matchStreak = 0;
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        flipped[firstSelectedIndex] = false;
        flipped[secondSelectedIndex] = false;
        _resetSelection();
      });
    }
  }

  void _resetSelection() {
    firstSelectedIndex = -1;
    secondSelectedIndex = -1;
  }

  void _restartGame() {
    _initializeGame();
    _startGameTimer();
  }

  void _onGameCompleted() {
    setState(() {
      gameCompleted = true;
    });
    _showRewardDialog();
  }

  void _showRewardDialog() {
    String reward = rewards[Random().nextInt(rewards.length)];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Congratulations!'),
          content: Text('You won: $reward'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _startGameTimer() {
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _updateChests() {
    if (points >= 20) unlockedChests[0] = true;
    if (points >= 40) unlockedChests[1] = true;
    if (matchCount >= 4) unlockedChests[2] = true;
    if (matchStreak >= 3) unlockedChests[3] = true;
    if (remainingTime > 15) unlockedChests[4] = true;

    // Start the fireworks animation for the unlocked chests
    for (int i = 0; i < unlockedChests.length; i++) {
      if (unlockedChests[i]) {
        // Reset the animation before starting
        _fireworksController.forward(from: 0).then((_) {
          // Reverse the animation after it finishes
          _fireworksController.reverse();
        });
      }
    }
  }

  Widget _buildChest(int index, String reward) {
    return Flexible(
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: unlockedChests[index] ? _showRewardDialog : null,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/chest.png',
                  width: 50,
                  height: 50,
                ),
                SizedBox(height: 4),
                Text(
                  reward,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.0),
                ),
              ],
            ),
          ),
          if (unlockedChests[index]) ...[
            // Fireworks animation when the chest is unlocked
            AnimatedBuilder(
              animation: _fireworksController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fireworksController.value,
                  child: SvgPicture.asset(
                    'assets/images/fireworks.svg',
                    width: 100,
                    height: 100,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foodie Memory Game'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _restartGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Match the Food Items!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // Grid of cards
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
              ),
              padding: EdgeInsets.all(16.0),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _flipCard(index), // Function to flip the card
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(flipped[index] || matched[index]),
                      decoration: BoxDecoration(
                        color: flipped[index] || matched[index]
                            ? Colors.white // Background color when flipped
                            : Colors.transparent, // Default color
                        image: flipped[index] || matched[index]
                            ? null // No image when flipped
                            : DecorationImage(
                                image: AssetImage(
                                    'assets/images/ITSA_BG.jpg'), // Your image path
                                fit: BoxFit.cover,
                              ),
                        borderRadius: BorderRadius.circular(
                            16.0), // Same radius as the card
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            flipped[index] || matched[index]
                                ? cards[index]
                                : '',
                            key: ValueKey(flipped[index] || matched[index]),
                            style: TextStyle(
                              fontSize: 24,
                              color: flipped[index] || matched[index]
                                  ? Colors.black
                                  : Colors.transparent, // Set text color
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Space between the grid and the progress bar
          SizedBox(height: 30.0), // Adjust height as needed
          // Progress bar
          Transform.translate(
            offset: Offset(0, -120), // Move up by 20 pixels
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(
                value: points / 100.0,
                minHeight: 10.0,
                color: Colors.green,
                backgroundColor: const Color.fromARGB(255, 186, 196, 250),
              ),
            ),
          ),
          // Chests Row
          Transform.translate(
            offset: Offset(0, -150), // Move up by 20 pixels; adjust as needed
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                rewards.length,
                (index) => _buildChest(index, rewards[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
