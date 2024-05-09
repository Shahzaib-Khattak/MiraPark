import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'BookingScreen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class PreviouseBooking extends StatefulWidget {
  final String userId;
  final String licensePlate;
  final String locationName;
  final String distance;
  final int latitude;
  final int longitude;
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

  String get end => DateTime.now().add(const Duration(minutes: 30)).toIso8601String();

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
    // Compare current time with end time to determine if booking time is over
    DateTime endTime = DateTime.parse(widget.end);
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

      // Follow redirects until we get a non-308 response
      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];

        // Make another POST request to the redirect URL
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': widget.userId}),
        );
      }

      // Now check the final response
      if (response.statusCode == 200) {
        dynamic data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            bookings = List<Map<String, String>>.from(data.map((e) => _convertDynamicToString(e)));
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
        title: Text('Booking Details'),
      ),
      body: Center(
        child: bookings.isEmpty
            ? CircularProgressIndicator()
            : ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return BookingCard(
              context: context,
              licensePlate: bookings[index]['licensePlate'] ?? '',
              start: bookings[index]['start'] ?? '',
              end: bookings[index]['end'] ?? '',
              location: bookings[index]['location'] ?? '',
              status: bookings[index]['status'] ?? '',
              isBookingTimeOver: _isBookingTimeOver,
              bookingEndTime: widget.end,
              userId: widget.userId,
            );
          },
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final BuildContext context;
  final String licensePlate;
  final String start;
  final String end;
  final String location;
  final String status;
  final bool isBookingTimeOver;
  final String bookingEndTime;
  final String userId;

  const BookingCard({
    Key? key,
    required this.context,
    required this.licensePlate,
    required this.start,
    required this.end,
    required this.location,
    required this.status,
    required this.isBookingTimeOver,
    required this.bookingEndTime,
    required this.userId,
  }) : super(key: key);

  Future<void> cancelBooking(BuildContext context) async {
    try {
      EasyLoading.instance
        ..indicatorType = EasyLoadingIndicatorType.pouringHourGlass
        ..loadingStyle = EasyLoadingStyle.custom
        ..indicatorColor = Colors.blue
        ..backgroundColor = Colors.transparent
        ..textColor = Colors.white;

      EasyLoading.show(
        status: 'Please wait until your booking is being cancelled...',
      );

      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/cancel-booking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'licensePlate': licensePlate,
          'location': location,
        }),
      );

      // Follow redirects until we get a non-308 response
      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];

        // Make another POST request to the redirect URL
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'licensePlate': licensePlate,
            'location': location,
          }),
        );
      }

      // Now check the final response
      if (response.statusCode == 200) {
        print('Booking cancelled successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking Cancelled Successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(seconds: 1));
        EasyLoading.dismiss(); // Dismiss EasyLoading
      } else if (response.statusCode == 404) {
        print('Booking not found');
      } else {
        throw Exception('Failed to cancel booking: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error cancelling booking: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();
    final endTime = DateTime.parse(bookingEndTime);

    return Card(
      margin: EdgeInsets.all(16.0),
      color: Colors.blueGrey[100],
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'License Plate: $licensePlate',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'Start Time: $start',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'End Time: $end',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'Location: $location',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              'Status: $status',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            if (status == 'active')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      cancelBooking(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      alignment: Alignment.center,
                    ),
                    child: Text('Cancel Booking'),
                  ),
                ],
              ),

            if (status == 'expired')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            userId: userId,
                            licensePlate: licensePlate,
                            locationName: location,  distance: '', latitude: 1213, longitude: 1311, StartTime: '', EndTime: '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      alignment: Alignment.center,
                    ),
                    child: Text('Rebook'),
                  ),
                ],
              ),

          ],
        ),
      ),
    );
  }
}
