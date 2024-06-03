import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('FAQs', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          ExpansionTile(
            title: Text('How to book a Parking Spot?'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Here is how you can book a parking spot...'), // Replace with actual answer
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How to add money in wallet?'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('To add money to your wallet, you need to...'), // Replace with actual answer
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How to change language?'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('You can change the language by going to...'), // Replace with actual answer
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How to Logout my account?'),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('To logout from your account, please...'), // Replace with actual answer
              ),
            ],
          ),
          // Add more questions as needed
        ],
      ),
    );
  }
}
