import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'modify_feature.dart';

class FeatureProductModal {
  // Static method to show the feature product modal
  static void showFeatureModal(BuildContext context, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onVerticalDragUpdate: (_) {}, // Preventing the modal from closing
          child: _FeatureProductModalContent(
              userName: userName), // Pass userName here
        );
      },
    );
  }
}

class _FeatureProductModalContent extends StatefulWidget {
  final String userName;

  _FeatureProductModalContent({required this.userName});

  @override
  _FeatureProductModalContentState createState() =>
      _FeatureProductModalContentState();
}

class _FeatureProductModalContentState
    extends State<_FeatureProductModalContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    // Adjust modal height dynamically based on current page
    double modalHeight = _currentPage == 2
        ? MediaQuery.of(context).size.height * 0.9 // Modal covers 90% on page 3
        : 400; // Default height for page 1 and page 2

    return AnimatedContainer(
      duration: Duration(milliseconds: 300), // Smooth transition
      height: modalHeight,
      curve: Curves.easeInOut, // Smooth transition curve
      decoration: BoxDecoration(
        color: Color(0xFFE1D4C2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page; // Update current page index
                });
              },
              children: [
                _buildPageContent(
                  "",
                  "Here, you can modify how the featured product will be presented to the customers",
                ),
                _buildPageContent(
                  "",
                  "By modifying the parameters here, you can change the recommended parameters to your liking",
                ),
                FeatureConfigPage(userName: widget.userName),
              ],
            ),
          ),
          // Show SmoothPageIndicator only on Page 0 and Page 1
          if (_currentPage < 2)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 2, // Only 2 dots now for 2 pages
                effect: WormEffect(
                  dotColor: Colors.grey,
                  activeDotColor: Color(0xFF291C0E),
                  dotHeight: 8.0, // Smaller height for the dots
                  dotWidth: 8.0, // Smaller width for the dots
                ),
              ),
            ),
          if (_currentPage != 2) // Show buttons only if not on page 3
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Button (Cancel/Previous)
                TextButton(
                  onPressed: () {
                    if (_currentPage == 0) {
                      Navigator.of(context).pop(); // Close the modal on page 0
                    } else {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    _currentPage == 0 ? 'Cancel' : 'Previous',
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                // Right Button (Next)
                TextButton(
                  onPressed: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Finalize the process and close modal after page 3
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    _currentPage == 2 ? 'Finish' : 'Next',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildPageContent(String title, String description) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                fontSize: 26, // Larger font size for title
                fontWeight: FontWeight.w700, // Bold for prominence
                color: Color(0xFF291C0E), // Dark color for title
                letterSpacing: 0.5, // Slight letter spacing for emphasis
              ),
            ),
          SizedBox(
              height: 12), // Increased spacing between title and description
          Text(
            description,
            style: TextStyle(
              fontSize: 18, // Larger font size for description
              fontWeight: FontWeight.normal, // Normal weight for description
              color: Color(0xFF291C0E), // Consistent color for readability
              height: 1.6, // Line height for better readability
            ),
          ),
        ],
      ),
    );
  }
}
