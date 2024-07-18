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
  final String lat;
  final String lng;

  PaymentScreen({
    required this.startTime,
    required this.endTime,
    required this.licensePlate,
    required this.location,
    required this.userId,
    required this.price,
    required this.lat,
    required this.lng,
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
  late StreamSubscription _sub;
  bool paymentSuccessful = false;
  bool isGetDirectionButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    print('Entering initState function::' + widget.location);
    print('Entering initState function::' + widget.licensePlate);
    print('Entering initState function::' + widget.price);
  }

  Future<void> createPayment() async {
    try {
      print('Entering createPayment function');
      print('Location: ${widget.location}');
      print('Price: ${widget.price}');

      final response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'intent': 'sale',
          'payer': {'payment_method': 'paypal'},
          'redirect_urls': {
            'return_url': 'http://mi-park-backend-iota.vercel.app/success',
            'cancel_url': 'http://mi-park-backend-iota.vercel.app/cancel'
          },
          'transactions': [
            {
              'item_list': {
                'items': [
                  {
                    'location': widget.location,
                    'price': widget.price,
                    'currency': 'EUR',
                    'name': 'Mira Park'
                  }
                ]
              },
              'amount': {'currency': 'EUR', 'total': widget.price},
              'description': 'Your Booking for the specific Parking Slot will be confirmed once your payment is successful'
            }
          ]
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response data: $responseData');
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
      } else if (response.statusCode == 301 || response.statusCode == 308) {
        final newLocation = response.headers['location'];
        if (newLocation != null) {
          final newResponse = await http.post(
            Uri.parse(newLocation),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'intent': 'sale',
              'payer': {'payment_method': 'paypal'},
              'redirect_urls': {
                'return_url': 'http://mi-park-backend-iota.vercel.app/success',
                'cancel_url': 'http://mi-park-backend-iota.vercel.app/cancel'
              },
              'transactions': [
                {
                  'item_list': {
                    'items': [
                      {
                        'location': widget.location,
                        'price': widget.price,
                        'currency': 'EUR',
                        'name': 'Mira Park'
                      }
                    ]
                  },
                  'amount': {'currency': 'EUR', 'total': widget.price},
                  'description': 'Your Booking for the specific Parking Slot will be confirmed once your payment is successful'
                }
              ]
            }),
          );
          if (newResponse.statusCode == 200) {
            final newResponseData = jsonDecode(newResponse.body);
            print('New response data: $newResponseData');
            Future.delayed(Duration(seconds: 5));
            setState(() {
              isGetDirectionButtonEnabled = true;
            });
            if (newResponseData.containsKey('approval_url')) {
              final approvalUrl = newResponseData['approval_url'];
              if (await canLaunch(approvalUrl)) {
                await launch(approvalUrl);
              } else {
                throw 'Could not launch $approvalUrl';
              }
            } else {
              throw Exception('Approval URL not found in payment response');
            }
          } else {
            throw Exception('Failed to create payment at new location: ${newResponse.reasonPhrase}');
          }
        } else {
          throw Exception('Redirect location not found');
        }
      } else {
        throw Exception('Failed to create payment: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error: $error');
      throw Exception('Error: $error');
    }
  }


  Future<void> navigateToGoogleMaps() async {
    String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.lng}';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  @override
  void dispose() {
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    _sub.cancel();
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
                    print('Payment created successfully');
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
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: isGetDirectionButtonEnabled
                      ? () {
                    navigateToGoogleMaps();
                    print('Navigating to Google Maps');
                  }
                      : null,
                  child: Opacity(
                    opacity: isGetDirectionButtonEnabled ? 1.0 : 0.5,
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
                        'Get Direction',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
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
