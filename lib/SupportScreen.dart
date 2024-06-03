import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';



class SupportScreen extends StatelessWidget {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Support', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final whatsappNumber = '+923150597750';
                final whatsappUrl = "whatsapp://send?phone=$whatsappNumber";

                if (await canLaunch (whatsappUrl)) {
                  await launch(whatsappUrl);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cannot open WhatsApp')),
                  );
                }
              },
              icon: Icon(Icons.phone, color: Colors.white),
              label: Text('Call Us'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final email = 'shahzaibnaseem521@gmail.com';
                final subject = Uri.encodeComponent('Subject for Your Email');
                final body = Uri.encodeComponent('Body of your email');
                final mailtoUrl = 'mailto:$email?subject=$subject&body=$body';

                if (await canLaunch(mailtoUrl)) {
                  await launch(mailtoUrl);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cannot open mail app')),
                  );
                }
              },
              icon: Icon(Icons.mail, color: Colors.white),
              label: Text('Mail Us'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 20),
            Text('Write Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number/Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Your feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final email = 'shahzaibnaseem521@gmail.com';
                final subject = Uri.encodeComponent('Feedback from App User');
                final body = Uri.encodeComponent('Contact: ${_phoneController.text}\n\nFeedback: ${_messageController.text}');
                final mailtoUrl = 'mailto:$email?subject=$subject&body=$body';

                if (await canLaunch(mailtoUrl)) {
                  await launch(mailtoUrl);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot open mail app'),
                    ),
                  );
                }
              },
              child: Text('SUBMIT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}