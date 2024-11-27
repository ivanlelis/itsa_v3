import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onCartPressed;
  final String userName;
  final String uid;

  const CustomAppBar({
    super.key,
    required this.scaffoldKey,
    required this.onCartPressed,
    required this.userName,
    required this.uid,
  });

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80); // Set preferred height
}

class _CustomAppBarState extends State<CustomAppBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  bool _isLoading = false;
  final GlobalKey _searchBarKey = GlobalKey();
  late final FirebaseFirestore _firestore;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isEmpty) {
        _hideOverlay(); // Hide overlay if search is empty
      } else {
        _fetchSuggestions(_searchController.text); // Fetch suggestions
      }
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      _hideOverlay(); // Hide overlay if the query is empty
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String lowerCaseQuery = query.toLowerCase();

    try {
      print('Fetching suggestions for: $query');

      // Fetch all products (you can add limit or pagination here)
      QuerySnapshot snapshot = await _firestore.collection('products').get();

      List<String> fetchedSuggestions = snapshot.docs
          .map((doc) {
            final productName =
                (doc.data() as Map<String, dynamic>)['productName'] as String;
            // Check if productName starts with the lowercase query
            if (productName.toLowerCase().startsWith(lowerCaseQuery)) {
              return productName;
            }
            return null; // Skip products that do not match
          })
          .where((productName) => productName != null) // Filter out nulls
          .cast<String>() // Convert the filtered list to List<String>
          .toList();

      print('Fetched suggestions: $fetchedSuggestions');

      setState(() {
        _suggestions = fetchedSuggestions;
      });

      if (_suggestions.isNotEmpty) {
        _showOverlay(); // Show overlay if there are suggestions
      } else {
        _hideOverlay(); // Hide overlay if no suggestions found
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox =
        _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return; // Safety check

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double searchBarHeight = renderBox.size.height;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: renderBox.size.width,
          top: offset.dy + searchBarHeight + 8, // Position below the search bar
          left: offset.dx,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildSearchResults(),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF6E473B),
      toolbarHeight: 80,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          widget.scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          key: _searchBarKey, // Attach the key here
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _hideOverlay();
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: widget.onCartPressed,
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No results found.',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _suggestions.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            _suggestions[index],
            style: const TextStyle(color: Colors.black),
          ),
          onTap: () {
            _searchController.text = _suggestions[index];
            _hideOverlay();
            // Add action, e.g., navigate to product details
          },
        );
      },
    );
  }
}
