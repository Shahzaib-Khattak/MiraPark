import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'BookingScreen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PreviouseBooking extends StatefulWidget {
  final String userId;
  final String licensePlate;
  final String locationName;
  final String distance;
  final double latitude;
  final double longitude;
  final String StartTime;
  final String EndTime;

  const PreviouseBooking({
    Key? key,
    required this.userId,
    required this.licensePlate,
    required this.locationName,
    required this.distance,
    required this.latitude,
    required this.longitude,
    required this.StartTime,
    required this.EndTime,
  }) : super(key: key);

  @override
  _PreviouseBookingState createState() => _PreviouseBookingState();
}

class _PreviouseBookingState extends State<PreviouseBooking> {
  bool _isBookingTimeOver = false;
  List<Map<String, String>> bookings = [];

  @override
  void initState() {
    super.initState();
    previousBookings();
    _checkBookingTime();
  }

  void _checkBookingTime() {
    DateTime endTime = DateTime.tryParse(widget.EndTime) ?? DateTime.now();
    if (DateTime.now().isAfter(endTime)) {
      setState(() {
        _isBookingTimeOver = true;
      });
    }
  }

  Future<void> previousBookings() async {
    try {
      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/previous-bookings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}),
      );

      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];

        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': widget.userId}),
        );
      }

      if (response.statusCode == 200) {
        dynamic data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            bookings = List<Map<String, String>>.from(data.map((e) => _convertDynamicToString(e)));
            // Sort bookings: active first, then expired sorted by end time descending
            bookings.sort((a, b) {
              if (a['status'] == 'active' && b['status'] != 'active') {
                return -1;
              } else if (a['status'] != 'active' && b['status'] == 'active') {
                return 1;
              } else if (a['status'] == 'expired' && b['status'] == 'expired') {
                DateTime endA = DateTime.tryParse(a['end']!) ?? DateTime.now();
                DateTime endB = DateTime.tryParse(b['end']!) ?? DateTime.now();
                return endB.compareTo(endA); // Descending order
              }
              return 0;
            });
          });
          print('Received bookings data: $bookings'); // Print received data
        } else {
          throw Exception('Invalid data format received');
        }
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (error) {
      print('Error fetching bookings: $error');
      // Handle error
    }
  }

  Map<String, String> _convertDynamicToString(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bookingdetails),
      ),
      body: Center(
        child: bookings.isEmpty
            ? CircularProgressIndicator()
            : ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return BookingCard(
              licensePlate: bookings[index]['licensePlate'] ?? '',
              start: bookings[index]['start'] ?? '',
              end: bookings[index]['end'] ?? '',
              location: bookings[index]['location'] ?? '',
              status: bookings[index]['status'] ?? '',
              isBookingTimeOver: _isBookingTimeOver,
              bookingEndTime: widget.EndTime,
              userId: widget.userId,
              euid: bookings[index]['euid'] ?? '',
              username: bookings[index]['username'] ?? '',
            );
          },
        ),
      ),
    );
  }
}

class BookingCard extends StatefulWidget {
  final String licensePlate;
  final String start;
  final String end;
  final String location;
  final String status;
  final bool isBookingTimeOver;
  final String bookingEndTime;
  final String userId;
  final String euid;
  final String username;

  const BookingCard({
    Key? key,
    required this.licensePlate,
    required this.start,
    required this.end,
    required this.location,
    required this.status,
    required this.isBookingTimeOver,
    required this.bookingEndTime,
    required this.userId, required this.euid, required this.username,
  }) : super(key: key);

  @override
  _BookingCardState createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool isBarrierUp = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      color: Colors.green[300],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'License Plate: ${widget.licensePlate}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'Start Time: ${widget.start}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'End Time: ${widget.end}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'Location: ${widget.location}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'Status: ${widget.status}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            if (widget.status == 'active')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      cancelBooking(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[300],
                      shape: StadiumBorder(),
                      alignment: Alignment.center,
                    ),
                    child: Text(
                      'Cancel Booking',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Barrier Status',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: isBarrierUp,
                        onChanged: (value) {
                          setState(() {
                            isBarrierUp = value;
                          });
                          if (isBarrierUp) {
                            sendBarrierUpRequest();
                          } else {
                            sendBarrierDownRequest();
                          }
                        },
                        activeColor: Colors.blue,
                        inactiveTrackColor: Colors.white,
                        activeTrackColor: Colors.white,
                        inactiveThumbColor: Colors.black,
                      ),
                      Text(
                        isBarrierUp ? 'Barrier Down' : 'Barrier Up',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (widget.status == 'expired')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            userId: widget.userId,
                            licensePlate: widget.licensePlate,
                            locationName: widget.location,
                            distance: '',
                            latitude: 0.0,
                            longitude: 0.0,
                            StartTime: '',
                            EndTime: '',
                            euid: widget.euid,
                            username: widget.username,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      alignment: Alignment.centerRight,
                    ),
                    child: Text(
                      'Rebook',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }


  Future<void> cancelBooking(BuildContext context) async {
    try {
      EasyLoading.instance
        ..indicatorType = EasyLoadingIndicatorType.pouringHourGlass
        ..loadingStyle = EasyLoadingStyle.custom
        ..indicatorColor = Colors.blue
        ..backgroundColor = Colors.transparent
        ..textColor = Colors.white;

      EasyLoading.show(
        status: AppLocalizations.of(context)!.pleasewaituntillyourbookingisbeingcancelled,
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: false,
      );

      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/cancel-booking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'licensePlate': widget.licensePlate,
          'location': widget.location,
        }),
      );

      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': widget.userId,
            'licensePlate': widget.licensePlate,
            'location': widget.location,
          }),

        );
      }

      if (response.statusCode == 200) {
        print('Booking cancelled successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking Cancelled Successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss();
      } else if (response.statusCode == 404) {
        print('Booking not found');
      } else {
        throw Exception('Failed to cancel booking: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error cancelling booking: $error');
    }
  }

  Future<void> sendBarrierDownRequest() async {
    if (widget.userId.isEmpty) {
      return;
    }

    final url = 'http://mi-park-backend-iota.vercel.app/barrier_down';
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'userId': widget.userId,
      'euid': widget.euid,
      'username': widget.username,
    });

    try {

      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];
        if (redirectUrl == null) {
          throw Exception('Redirect URL is null');
        }

        print('Redirecting to: $redirectUrl');

        response = await http.post(
          Uri.parse(redirectUrl),
          headers: headers,
          body: body,
        );

        print('Redirect response status code: ${response.statusCode}');
        print('Redirect response headers: ${response.headers}');
        print('Redirect response body: ${response.body}');
      }

    } catch (error) {
      print('Error sending barrier down request: $error');
    }
  }
  Future<void> sendBarrierUpRequest() async {
    if (widget.userId.isEmpty) {
      return;
    }

    try {
      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/barrier_up'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.userId,
          'euid': widget.euid,
          'username': widget.username,
        }),
      );

      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': widget.userId,
            'euid': widget.euid,
            'username': widget.username,}),
        );
      }

    } catch (error) {
      print('Error sending barrier up request: $error');
    }
  }
}