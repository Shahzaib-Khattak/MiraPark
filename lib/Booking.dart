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
  final int latitude;
  final int longitude;

  final StartTime;

  final EndTime;

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
              bookingEndTime: widget.end,
              userId: widget.userId,
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

  const BookingCard({
    Key? key,
    required this.licensePlate,
    required this.start,
    required this.end,
    required this.location,
    required this.status,
    required this.isBookingTimeOver,
    required this.bookingEndTime,
    required this.userId,
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
    DateTime.parse(widget.bookingEndTime);

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
              AppLocalizations.of(context)!.licenseplate + ': ${widget.licensePlate}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              AppLocalizations.of(context)!.starttime +': ${widget.start}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              AppLocalizations.of(context)!.endtime + ': ${widget.end}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              AppLocalizations.of(context)!.location +': ${widget.location}',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            Text(
              AppLocalizations.of(context)!.status + ': ${widget.status}',
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
                    child: Text(AppLocalizations.of(context)!.cancelbooking,
                        style: TextStyle(color: Colors.white)),
                  ),
                  Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.barrierstatus ,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),),
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
                  )

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
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      alignment: Alignment.centerRight,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.rebook ,
                      style: TextStyle(color: Colors.white),),
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

    try {
      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/barrier_down'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': widget.userId}),
      );

      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': widget.userId}),
        );
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
        body: json.encode({'userId': widget.userId}),
      );

      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': widget.userId}),
        );
      }

    } catch (error) {
      print('Error sending barrier up request: $error');
    }
  }
}