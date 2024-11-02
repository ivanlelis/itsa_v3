// ignore_for_file: file_names, library_private_types_in_public_api

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';

class ScratchCardGrid extends StatefulWidget {
  const ScratchCardGrid({super.key});

  @override
  _ScratchCardGridState createState() => _ScratchCardGridState();
}

class _ScratchCardGridState extends State<ScratchCardGrid>
    with SingleTickerProviderStateMixin {
  final int gridCount = 16;
  int revealedCount = 0;
  int scratchChances = 5;
  bool gameCompleted = false;
  late List<String> shuffledRewards;
  late AnimationController _animationController;
  late ConfettiController _confettiController;
  String? rewardToShow;

  List<bool> revealedCards = List<bool>.filled(16, false);

  final List<String> rewards = [
    "🎉 30% off!",
    "💰 50% off!",
    "😊 Try Again",
    "🍀 3 Free Deliveries!",
    "🙁 Better Luck Next Time"
  ];

  @override
  void initState() {
    super.initState();
    revealedCards = List<bool>.filled(gridCount, false);
    resetGame();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _confettiController = ConfettiController(duration: Duration(seconds: 1));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void onCardRevealed(String reward) {
    setState(() {
      if (gameCompleted) return; // Prevent further actions if game is completed

      if (reward == "🙁 Better Luck Next Time") {
        gameCompleted = true;
        showGameOverModal(
          title: "Game Over! Better Luck Next Time!",
          playAgain: resetGame,
        );
      } else if (reward == "😊 Try Again") {
        scratchChances++;
      } else {
        revealedCount++;
        showRewardOverlay(reward); // Show reward overlay for winning cards
      }

      scratchChances--; // Decrement chances

      // Check for game completion if there are no chances left
      if (scratchChances <= 0) {
        gameCompleted = true;
        showGameOverModal(
          title: "Game Over! No more chances left.",
          playAgain: resetGame,
        );
      }
    });
  }

  void showGameOverModal(
      {required String title, required VoidCallback playAgain}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Thank you for playing! Click below to claim any eligible rewards.",
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Logic for claiming rewards can be added here
                  Navigator.of(context).pop(); // Close the modal
                  resetGame(); // Reset the game when claiming rewards
                },
                child: Text("Claim Rewards"),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the modal
                  playAgain(); // Call the resetGame function when playing again
                },
                child: Text("Play Again"),
              ),
            ),
          ],
        );
      },
    );
  }

  void showRewardOverlay(String reward) {
    setState(() {
      rewardToShow = reward;
    });
    _animationController.forward(from: 0);
    _confettiController.play(); // Play confetti when reward overlay shows

    // Hide the reward after a short delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          rewardToShow = null;
        });
        _confettiController.stop(); // Stop confetti after overlay disappears
      }
    });
  }

  void resetGame() {
    setState(() {
      revealedCount = 0; // Reset the revealed count
      scratchChances = 5; // Reset chances
      gameCompleted = false; // Mark the game as not completed
      shuffledRewards = _generateShuffledRewards(); // Generate new rewards
      revealedCards =
          List<bool>.filled(gridCount, false); // Reset revealed cards
    });
  }

  List<String> _generateShuffledRewards() {
    final rewardsList = List<String>.generate(
        gridCount, (index) => rewards[index % rewards.length]);
    rewardsList.shuffle(Random());
    return rewardsList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fully transparent background
      extendBodyBehindAppBar:
          true, // Allows the body to extend behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Scratch and Win",
          style: GoogleFonts.pacifico(
            textStyle: TextStyle(
              fontSize: MediaQuery.of(context).size.width *
                  0.07, // Increased font size
              fontWeight: FontWeight.bold,
              color: Colors.yellowAccent,
              letterSpacing: 0.1,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 8,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/images/s&w.png'), // Add your background image here
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 100), // Offset to start below AppBar
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(gridCount, (index) {
                      final reward = shuffledRewards[index];
                      return SizedBox(
                        width: MediaQuery.of(context).size.width / 4 - 12,
                        height: MediaQuery.of(context).size.width / 4 - 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ScratchCard(
                            rewardText: reward,
                            onReveal: (reward) {
                              onCardRevealed(reward);
                              revealedCards[index] =
                                  true; // Mark this card as revealed
                            },
                            isWinningCard:
                                reward != "🙁 Better Luck Next Time" &&
                                    reward != "😊 Try Again",
                            revealed:
                                revealedCards[index], // Pass the revealed state
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (!gameCompleted) SizedBox(height: 10),
                  if (!gameCompleted)
                    Column(
                      children: [
                        Text(
                          "Chances left: $scratchChances",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Winning cards revealed: $revealedCount",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (rewardToShow != null)
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.elasticOut,
                ),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Congratulations!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        rewardToShow!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (rewardToShow != null)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.blue,
                      Colors.green,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                    ],
                    numberOfParticles: 60,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ScratchCard extends StatelessWidget {
  final String rewardText;
  final Function(String) onReveal;
  final bool isWinningCard;
  final bool revealed; // New parameter to indicate if revealed

  const ScratchCard({super.key, 
    required this.rewardText,
    required this.onReveal,
    required this.isWinningCard,
    required this.revealed, // Accept revealed state
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: revealed // Check if the card is revealed
              ? Center(
                  child: Text(
                    rewardText,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )
              : Scratcher(
                  brushSize: 25,
                  threshold: 0,
                  color: Colors.grey,
                  image: Image.asset("assets/images/ITSA_BG.jpg"),
                  onScratchEnd: () {
                    onReveal(rewardText); // Reveal the reward
                  },
                  child: Center(
                    child: Text(
                      rewardText,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
