import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';



class PaymentScreen extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final String licensePlate;
  final String location;
  final String userId;
  final String price;
  final String email;

  PaymentScreen({
    required this.startTime,
    required this.endTime,
    required this.licensePlate,
    required this.location,
    required this.userId,
    required this.price,
    required this.email,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  TextEditingController cardNumberController = TextEditingController();
  TextEditingController expiryDateController = TextEditingController();
  TextEditingController cvvController = TextEditingController();
  bool isLoading = false;
  bool showConfirmationText = false;
  bool showAlmostDoneText = false;
  bool showBookingConfirmedText = false;
  bool bookingConfirmed = false;
  String bookingDetails = '';

  Future<void> createPayment() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.59:3000/pay'), // Remove duplicate 'http://'
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'intent': 'sale',
          'payer': {'payment_method': 'paypal'},
          'redirect_urls': {
            'return_url': 'http://192.168.0.108:3000/success',
            'cancel_url': 'http://192.168.0.108:3000/cancel'
          },
          'transactions': [
            {
              'item_list': {
                'items': [
                  {
                    'name': 'Red Sox Hat',
                    'sku': '001',
                    'price': '25.00',
                    'currency': 'USD',
                    'quantity': 1
                  }
                ]
              },
              'amount': {'currency': 'USD', 'total': '25.00'},
              'description': 'Hat for the best team ever'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('approval_url')) {
          final approvalUrl = responseData['approval_url'];
          if (await canLaunch(approvalUrl)) {
            await launch(approvalUrl);
          } else {
            throw 'Could not launch $approvalUrl';
          }
        } else {
          throw Exception('Approval URL not found in payment response');
        }
        Booknow();
      } else {
        throw Exception('Failed to create payment: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }


  Future<void> Booknow() async {
    try {
      var response = await http.post(
        Uri.parse('http://192.168.100.59:3000/create-booking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start': widget.startTime.toIso8601String(),
          'end': widget.endTime.toIso8601String(),
          'licensePlate': widget.licensePlate,
          'location': widget.location,
          'userId': widget.userId,
          'price': '10',
          'Email': 'naseem.shahzaib22@gmail.com',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          bookingConfirmed = true;
          bookingDetails = 'Booking created successfully';
        });
      } else {
        setState(() {
          bookingConfirmed = false;
          bookingDetails = 'Booking failed';
        });
      }
    } catch (error) {
      setState(() {
        bookingConfirmed = false;
        bookingDetails = 'Error: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    createPayment();
                  },
                  child: Container(
                    height: 50,
                    width: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                          Colors.blue.shade800,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(screenHeight * 0.2),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 0),
                          child: Image.asset(
                            'assets/paypal.png',
                            height: 40,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Text(
                            'Pay with PayPal',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text(
                'Or Enter Card Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryDateController,
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Implement payment confirmation logic here
                  },
                  child: Container(
                    height: 50,
                    width: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                          Colors.blue.shade800,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(screenHeight * 0.2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Confirm Payment',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
