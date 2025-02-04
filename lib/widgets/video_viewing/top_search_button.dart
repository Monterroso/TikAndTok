import 'package:flutter/material.dart';

/// TopSearchButton represents the search functionality located at the top-right.
class TopSearchButton extends StatelessWidget {
  const TopSearchButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search, color: Colors.white),
      onPressed: () {
        // TODO: Implement search functionality.
      },
    );
  }
} 