import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'Models/polylines.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


const kGoogleApiKey = 'AIzaSyBUtjCUeiVXJzek8eh30P7feb_dGLEVVjc';

class BookingScreen extends StatefulWidget {
  final String locationName;
  final String distance;
  final String userId;
  final double latitude; // Add latitude parameter
  final double longitude;
  final String licensePlate;
  final String StartTime;
  final String EndTime;


  BookingScreen({
    required this.licensePlate,
    required this.locationName,
    required this.distance,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.StartTime,
    required this.EndTime,

  });

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {

  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  late LatLng origin;
  late LatLng destination; // Declare destination
  String vehicleType = '';
  String plateNumber = '';
  String Email = '';
  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now().add(Duration(minutes: 30));
  bool bookingConfirmed = false;
  String bookingDetails = '';
  late Timer timer;
  bool isLoading = false;
  bool showConfirmationText = false;
  bool showAlmostDoneText = false;
  late PolylineResponse polylineResponse;
  late String totalDistance;
  late String totalTime;
  late Set<Polyline> polylinePoints;
  late Image appIcon; // Declare the appIcon variable
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;


  // Method to show notification
  Future<void> showNotification() async {
    // Calculate remaining time
    Duration remainingTime = endTime.difference(DateTime.now());

    // Create a unique notification ID for this notification
    int notificationId = widget.userId.hashCode;

    // Check if remaining time is less than 5 minutes

    // Check if remaining time is less than or equal to 5 minutes
    if (remainingTime <= Duration(minutes: 5)) {

      // Create the notification content
      NotificationContent content = NotificationContent(
        id: widget.userId.hashCode,
        channelKey: 'booking_channel',
        title: 'Attention!',
        body: 'There is less than 5 minutes remaining until Booking end time. Please consider rebooking or withdrawing your car.<br>Start time: ${DateFormat('hh:mm a').format(startTime)}<br>End time: ${DateFormat('hh:mm a').format(endTime)}',

        notificationLayout: NotificationLayout.BigText,
      );

      // Create the notification
      AwesomeNotifications().createNotification(
          content: content,
          actionButtons: [

            NotificationActionButton(
                key: 'DISMISS',
                label: 'Dismiss',
                actionType: ActionType.DismissAction,
                isDangerousOption: true)
          ]
      );

      // Cancel the timer
      timer.cancel();
    }
    else {
      // Create the notification content
      NotificationContent content = NotificationContent(
        id: notificationId, // Notification ID
        channelKey: 'booking_channel', // Channel key
        title: 'Booking Details', // Notification title
        body: 'Start time: ${DateFormat('hh:mm a').format(startTime)}<br>End time: ${DateFormat('hh:mm a').format(endTime)}', // Notification body
        notificationLayout: NotificationLayout.Default,



      );

      // Create the notification
      AwesomeNotifications().createNotification(
        content: content,
      );
      if (remainingTime < Duration(minutes: 5)) {


        // Show notification
        NotificationContent content = NotificationContent(
          id: notificationId, // Notification ID
          channelKey: 'booking_channel', // Channel key
          title: 'Booking Details', // Notification title
          body: 'Start time: ${DateFormat('hh:mm a').format(startTime)}<br>End time: ${DateFormat('hh:mm a').format(endTime)}', // Notification body
          notificationLayout: NotificationLayout.Default,
        );

      }

    }
  }
  String _formatDuration(Duration duration) {
    // Format duration as hours, minutes, and seconds
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours}:${twoDigitMinutes}:${twoDigitSeconds}';
  }

  void _launchGoogleMaps() async {
    const url = 'https://maps.google.com'; // URL for Google Maps
    if (await canLaunch(url)) {
      await launch(url); // Launch Google Maps if the URL is valid
    } else {
      throw 'Could not launch $url'; // Handle error if unable to launch Google Maps
    }
  }



  //Book now
  Future<void> Booknow() async {
    if (vehicleType.isEmpty || plateNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter all fields.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      EasyLoading.instance
        ..indicatorType = EasyLoadingIndicatorType.pouringHourGlass
        ..loadingStyle = EasyLoadingStyle.custom
        ..indicatorColor = Colors.blue
        ..backgroundColor = Colors.transparent
        ..textColor = Colors.white;

      EasyLoading.show(
        status: AppLocalizations.of(context)!.pleasewaituntillyourbookingisbeingconfirmed,
      );

      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/create-booking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start': startTime.toIso8601String(),
          'end': endTime.toIso8601String(),
          'licensePlate': plateNumber,
          'location': widget.locationName,
          'userId': widget.userId,
          'price': '10',
          'Email': 'naseem.shahzaib22@gmail.com',
        }),
      );

      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'start': startTime.toIso8601String(),
            'end': endTime.toIso8601String(),
            'licensePlate': plateNumber,
            'location': widget.locationName,
            'userId': widget.userId,
            'price': '10',
            'Email': 'naseem.shahzaib22@gmail.com',
          }),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 504) {
        print("Booking Done");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.bookingdonesuccessfully),
            duration: Duration(seconds: 2),
          ),
        );


        await Future.delayed(Duration(seconds: 1));
        _showBookingDetailsBottomSheet(context);
        showNotification(); // Ensure this is called
        NotificationContent(id: 1 , channelKey: '');

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.bookingfailed),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      EasyLoading.dismiss();
      setState(() {
        isLoading = false;
      });
    }
  }



  @override
  void initState() {
    super.initState();
    // Initialize awesome_notifications
    AwesomeNotifications().initialize(
      'resource://drawable/app_icon',
      [
        NotificationChannel(
          channelKey: 'booking_channel',
          channelName: 'Booking Notifications',
          channelDescription: 'Notifications for booking status',
          defaultColor: Color(0xFF5E76FF),
          ledColor: Colors.white,
          importance: NotificationImportance.High, // Set the importance to High to display heads-up notifications
          channelShowBadge: true, // Set to true if you want to show badges on the app icon
        ),
      ],
    );
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        startTime = DateTime.now();
      });
    });
  }


  @override
  void dispose() {
    timer.cancel(); // Cancel the timer when the screen is disposed
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900,
                  Colors.blue.shade800,
                  Colors.blue.shade400,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                SizedBox(

                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0 , vertical: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              color: Colors.white,
                              icon: Icon(Icons.arrow_back),
                              onPressed: () {
                                Navigator.pop(context);
                                // Add functionality to navigate back
                              },
                            ),
                            SizedBox(width: 10), // Add some horizontal spacing between the arrow and text
                            Text(
                              AppLocalizations.of(context)!.bookingscreen,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40), // Add more vertical space between the arrow and the location name
                        Center(
                          child: Text(
                            widget.locationName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 20), // Add more vertical space between the location name and the bottom
                      ],
                    ),
                  ),

                ),
                SizedBox(height: 20),
                Expanded(
                  child: SizedBox(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(60),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.vehicleType,
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              TextField(
                                decoration: InputDecoration(
                                  hintText:  AppLocalizations.of(context)!.entervehicletype,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    vehicleType = value;
                                  });
                                },
                              ),
                              SizedBox(height: 20),
                              Text(
                                AppLocalizations.of(context)!.licenseplatenumber,

                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.enterlicenseplatenumber,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    plateNumber = value;
                                  });
                                },
                              ),
                              SizedBox(height: 20),
                              Text(
                                AppLocalizations.of(context)!.selecttime,

                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                        onPressed: () async {
                                          TimeOfDay? selectedStartTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(startTime),
                                          );
                                          if (selectedStartTime != null) {
                                            setState(() {
                                              startTime = DateTime(
                                                startTime.year,
                                                startTime.month,
                                                startTime.day,
                                                selectedStartTime.hour,
                                                selectedStartTime.minute,
                                              );
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue, // Button color
                                          foregroundColor: Colors.white, // Text color
                                          padding: EdgeInsets.all(16), // Button padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8), // Button border radius
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.starttime,
                                              style: TextStyle(fontSize: 16),
                                            ),

                                            Text( ':', style: TextStyle(fontSize: 16),),
                                            SizedBox(width: 10),
                                            Text(
                                              '${DateFormat.Hm().format(startTime)}',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        )

                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                        onPressed: () async {
                                          TimeOfDay? selectedEndTime = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(endTime),
                                          );
                                          if (selectedEndTime != null) {
                                            setState(() {
                                              endTime = DateTime(
                                                endTime.year,
                                                endTime.month,
                                                endTime.day,
                                                selectedEndTime.hour,
                                                selectedEndTime.minute,
                                              );
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue, // Button color
                                          foregroundColor: Colors.white, // Text color
                                          padding: EdgeInsets.all(16), // Button padding
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8), // Button border radius
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.endtime,
                                              style: TextStyle(fontSize: 16),
                                            ),

                                            Text( ':', style: TextStyle(fontSize: 16),),
                                            SizedBox(width: 10),
                                            Text(
                                              '${DateFormat.Hm().format(endTime)}',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        )

                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 70),
                              Container(
                                alignment: Alignment.bottomCenter,
                                margin: EdgeInsets.only(bottom: 20),
                                child: ElevatedButton(
                                  onPressed: () {

                                    Booknow();


                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(80),
                                    ),
                                    minimumSize: Size(200, 50),
                                    backgroundColor: Colors.blue.shade800,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.booknow,

                                  ),
                                ),
                              ),

                              SizedBox(height: 40),
                              if (bookingConfirmed) _buildBookingCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> navigateToGoogleMaps(String destination) async {
    String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$destination';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch Google Maps';
    }
  }
  Future<void> navigateToMapScreen(BuildContext context) async {
    // This part is removed as we're not navigating to MapScreen anymore

    await Future.delayed(Duration(seconds: 2));
    origin = await _getCurrentLocation();
    destination = widget.locationName as LatLng;

    // Instead of navigating to MapScreen, we'll navigate to Google Maps
    await navigateToGoogleMaps(destination.toString());
  }


  void _showBookingDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: _buildBookingCard(),
        );
      },
    );
  }
  Widget _buildBookingCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10), // Adjust border radius as needed
        color: Colors.white, // Set card background color
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), // Adjust border radius as needed
                topRight: Radius.circular(10), // Adjust border radius as needed
              ),
              gradient: LinearGradient(
                colors: [Colors.blue[900]!, Colors.blue[800]!, Colors.blue[400]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                FractionalTranslation(
                  translation: Offset(0.0, 0.0), // Adjust value as needed to position the gradient
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(AppLocalizations.of(context)!.bookingdetails , style: TextStyle(fontSize: 20, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.licenseplate,
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold), // Applying bold style
                  ),
                  Text(
                    ':',
                    style: TextStyle(fontSize: 16.0), // No need for bold here
                  ),
                  SizedBox(width: 8.0), // Adds some space between the colon and the licensePlate
                  Text(
                    plateNumber,
                    style: TextStyle(fontSize: 16.0), // Applying regular style
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.starttime,
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold), // Applying bold style
                  ),
                  Text(
                    ':',
                    style: TextStyle(fontSize: 16.0), // No need for bold here
                  ),
                  SizedBox(width: 8.0), // Adds some space between the colon and the start time value
                  Text(
                    startTime.toIso8601String(),
                    style: TextStyle(fontSize: 16.0), // Applying regular style
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.endtime,
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold), // Applying bold style
                  ),
                  Text(
                    ':',
                    style: TextStyle(fontSize: 16.0), // No need for bold here
                  ),
                  SizedBox(width: 8.0), // Adds some space between the colon and the end time value
                  Text(
                    endTime.toIso8601String(),
                    style: TextStyle(fontSize: 16.0), // Applying regular style
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.location,
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold), // Applying bold style
                  ),
                  Text(
                    ':',
                    style: TextStyle(fontSize: 16.0), // No need for bold here
                  ),
                  SizedBox(width: 8.0), // Adds some space between the colon and the location value
                  Text(
                    widget.locationName,
                    style: TextStyle(fontSize: 16.0), // Applying regular style
                  ),
                ],
              ),
              SizedBox(height: 8.0),


            ],
          ),

          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                navigateToGoogleMaps( widget.locationName.toString());
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10), // Adjust vertical padding to reduce height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // Adjust border radius as needed
                ),
                minimumSize: Size(250, 40), // Adjust width and height as needed
                backgroundColor: Colors.blue.shade700, // Background color
                foregroundColor: Colors.white, // Text color
                elevation: 5, // Elevation
              ),
              child: Text(
                'Get Direction',
                style: TextStyle(fontSize: 16), // Text style
              ),
            ),
          ),

        ],
      ),
    );
  }


  Future<LatLng> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final GoogleMapController controller = await _controller;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
      BitmapDescriptor userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: LatLng(position.latitude, position.longitude),
          icon: userLocationIcon,
          infoWindow: const InfoWindow(title: 'Current Location'),
        ),
      );

      setState(() {});

      return LatLng(position.latitude, position.longitude); // Convert Position to LatLng
    } catch (e) {
      print("Error: $e");
      throw e; // Rethrow the error
    }
  }
}