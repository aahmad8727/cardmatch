import 'package:flutter/material.dart';

void main() => runApp(CardGameApp());

class CardGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      home: Scaffold(
        appBar: AppBar(title: Text('Card Matching Game')),
        body: CardGrid(),
      ),
    );
  }
}

class CardGrid extends StatelessWidget {
  //  data for 16 cards (4x4 grid)
  final List<int> cardNumbers = List.generate(16, (index) => index);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 columns in grid
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: cardNumbers.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              '${cardNumbers[index]}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
