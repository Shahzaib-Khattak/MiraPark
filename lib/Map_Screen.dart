import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'Models/polylines.dart';
import 'BookingScreen.dart';
import 'dart:math';
import 'dart:math' show cos, sqrt, asin;


const kGoogleApiKey = 'AIzaSyBUtjCUeiVXJzek8eh30P7feb_dGLEVVjc';

class CombinedScreen extends StatefulWidget {
  final String userId;

  CombinedScreen({required this.userId});
  @override
  _CombinedScreenState createState() => _CombinedScreenState();
}

class _CombinedScreenState extends State<CombinedScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  double containerPosition = 0.0; // Initial position
  double containerHeight = 50.0; // Initial height
  bool isContainerOpen = false; // Initial state



  static const CameraPosition initialPosition =
  CameraPosition(target: LatLng(33.7296, 73.0368), zoom: 14.0);

  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    double lat1 = point1.latitude * (pi / 180);
    double lon1 = point1.longitude * (pi / 180);
    double lat2 = point2.latitude * (pi / 180);
    double lon2 = point2.longitude * (pi / 180);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distanceInMeters = earthRadius * c;
    double distanceInKilometers = distanceInMeters / 1000; // Convert meters to kilometers

    return distanceInKilometers;
  }

  Future<void> _displayBottomSheet(BuildContext context, String markerTitle, LatLng markerPosition, LatLng userLocation, double distance) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate distance between user location and marker
    double distance = calculateDistance(userLocation, markerPosition);

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        width: screenWidth,
        height: 200,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
              child: Text(
                markerTitle,
                style: TextStyle(fontSize: 20),
              ),
            ),
            Text(
              " Your vehicle will be parked here",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('${distance.toStringAsFixed(2)} Km', "assets/Location.png"),
                _buildInfoItem("28 Spots", "assets/app_icon.png"), // Example, replace with actual info
                _buildInfoItem("€5/hour", "assets/Euro.png"), // Example, replace with actual info
              ],
            ),
            SizedBox(height: 22),
            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade900,
                    Colors.blue.shade800,
                    Colors.blue.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(screenHeight * 0.1),
              ),
              child: MaterialButton(
                onPressed: () {
                  // Navigate to BookingScreen and pass necessary information
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        userId: widget.userId,
                        latitude: markerPosition.latitude,
                        longitude: markerPosition.longitude,
                        locationName: markerTitle,
                        distance: distance.toStringAsFixed(2), licensePlate: '', StartTime: '', EndTime: '',
                      ),
                    ),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenHeight * 0.1),
                ),
                child: Center(
                  child: Text(
                    "Book Now",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String value, String imagePath) {
    double imageWidth = 18;
    double imageHeight = 18;

    if (imagePath == "assets/Euro.png") {
      imageWidth = 14;
      imageHeight = 14;
    } else if (imagePath == "assets/Location.png") {
      imageWidth = 20;
      imageHeight = 20;
    } else if (imagePath == "assets/app_icon.png") {
      imageWidth = 20;
      imageHeight = 20;
    }

    return Row(
      children: [
        Image.asset(
          imagePath,
          width: imageWidth,
          height: imageHeight,
        ),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  late Set<Marker> _markers;
  late LatLng origin;
  late LatLng destination;
  late PolylineResponse polylineResponse;
  late String totalDistance;
  late String totalTime;
  late Set<Polyline> polylinePoints;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markers = {};
    origin = LatLng(33.65146,72.95310);
    destination = LatLng(33.6844 , 73.0479);
    polylineResponse = PolylineResponse();
    totalDistance = "";
    totalTime = "";
    polylinePoints = {};
    _addRandomMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            mapType: MapType.normal,
            markers: _markers,
            polylines: polylinePoints,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned(
            top: 55,
            left: 20,
            right: 20,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Places',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: _handleSearchTextChanged,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton.extended(
              onPressed: _getCurrentLocation, // Call the function to get the current location
              label: const Text("Current Location"),
              icon: const Icon(Icons.location_on),
            ),
          ),
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: GestureDetector(
          //     onVerticalDragUpdate: (details) {
          //       // Update the container position based on vertical drag
          //       setState(() {
          //         containerPosition += details.primaryDelta!;
          //         // Limit the container position to the height of the screen
          //         containerPosition = containerPosition.clamp(0.0, MediaQuery.of(context).size.height - containerHeight);
          //       });
          //     },
          //     onVerticalDragEnd: (details) {
          //       // Determine whether to fully open or close the container based on the drag end velocity
          //       if (details.primaryVelocity! < 0) {
          //         // User swiped upward, fully open the container
          //         setState(() {
          //           isContainerOpen = true;
          //         });
          //       } else {
          //         // User swiped downward, close the container
          //         setState(() {
          //           isContainerOpen = false;
          //         });
          //       }
          //     },
          //     child: AnimatedContainer(
          //
          //       duration: Duration(milliseconds: 300),
          //       curve: Curves.easeInOut,
          //       height: isContainerOpen ? MediaQuery.of(context).size.height : containerHeight,
          //       color: Colors.white,
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: [
          //           Icon(Icons.arrow_drop_up),
          //           Text(
          //             "Parking near You",
          //             style: TextStyle(
          //               fontSize: 18,
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //           // Add additional widgets inside the container as needed
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> _handleSearchTextChanged(String searchText) async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: kGoogleApiKey,
      onError: _onError,
      mode: Mode.overlay,
      language: 'en',
      strictbounds: false,
      types: [""],
      hint: searchText,
      components: [
        Component(Component.country, "pk"),
        Component(Component.country, "usa"),
      ],
    );

    _displayPrediction(p!, Scaffold.of(context));
  }

  void _onError(PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.errorMessage!),
      ),
    );
  }

  Future<void> _displayPrediction(
      Prediction p, ScaffoldState? currentState) async {
    GoogleMapsPlaces places = GoogleMapsPlaces(
      apiKey: kGoogleApiKey,
      apiHeaders: await const GoogleApiHeaders().getHeaders(),
    );

    PlacesDetailsResponse detail =
    await places.getDetailsByPlaceId(p.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId("0"),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: detail.result.name),
      ),
    );

    setState(() {});

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0));
  }

  // void navigateToBookingScreen(String markerTitle) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => BookingScreen(locationName: markerTitle)),
  //     );
  //   }

  Future<void> _drawPolyline() async {
    try {
      var response = await http.post(
        Uri.parse(
          "https://maps.googleapis.com/maps/api/directions/json?key=" +
              kGoogleApiKey +
              "&units=metric&origin=" +
              origin.latitude.toString() +
              "," +
              origin.longitude.toString() +
              "&destination=" +
              destination.latitude.toString() +
              "," +
              destination.longitude.toString() +
              "&mode=driving",
        ),
      );

      if (response.statusCode == 200) {
        polylineResponse =
            PolylineResponse.fromJson(jsonDecode(response.body));

        totalDistance =
        polylineResponse.routes![0].legs![0].distance!.text!;
        totalTime = polylineResponse.routes![0].legs![0].duration!.text!;

        _markers.clear();
        polylinePoints.clear();

        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: origin,
            infoWindow: const InfoWindow(title: 'Origin'),
          ),
        );

        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            infoWindow: const InfoWindow(title: 'Destination'),
          ),
        );

        // Add polyline if available
        if (polylineResponse.routes != null &&
            polylineResponse.routes!.isNotEmpty &&
            polylineResponse.routes![0].overviewPolyline != null) {
          List<LatLng> decodedPolyline = decodeEncodedPolyline(
              polylineResponse.routes![0].overviewPolyline!.points!);
          polylinePoints.add(
            Polyline(
              polylineId: const PolylineId('polyline'),
              points: decodedPolyline,
              width: 3,
              color: Colors.blueAccent,
            ),
          );
        }

        setState(() {});
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<Position> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final GoogleMapController controller = await _controller.future;
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

      return position; // Return the obtained position
    } catch (e) {
      print("Error: $e");
      throw e; // Rethrow the error
    }
  }

  List<LatLng> decodeEncodedPolyline(String encoded) {
    List<List<num>> decoded = _decodePolyline(encoded);
    List<LatLng> latLngList = decoded
        .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
        .toList();
    return latLngList;
  }

  List<List<num>> _decodePolyline(String encoded) {
    List<List<num>> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      double latLngLat = lat / 1E5;
      double latLngLng = lng / 1E5;
      polyline.add([latLngLat, latLngLng]);
    }
    return polyline;
  }


  void _addRandomMarkers() async {
    final Random random = Random();
    try {
      Position position = await _getCurrentLocation();
      LatLng userLocation = LatLng(position.latitude, position.longitude);
      final double lat = userLocation.latitude;
      final double lng = userLocation.longitude;


      for (int i = 0; i < 5; i++) {
        double randomLat = lat + random.nextDouble() * 0.01;
        double randomLng = lng + random.nextDouble() * 0.01;
        double distance = calculateDistance(userLocation, LatLng(randomLat, randomLng));


        _markers.add(
            Marker(
              markerId: MarkerId('12345'),
              position: LatLng(33.6844 , 73.0479),
              infoWindow: InfoWindow(title: 'Islamabad'),
              onTap: () {
                _displayBottomSheet(context, 'Islamabad', LatLng(33.6844 , 73.0479), userLocation, distance);
              },
            )
        );
        _markers.add(
            Marker(
              markerId: MarkerId('12345'),
              position: LatLng(33.6844 , 73.0479),
              infoWindow: InfoWindow(title: 'Islamabad'),
              onTap: () {
                _displayBottomSheet(context, 'Islamabad', LatLng(33.6844 , 73.0479), userLocation, distance);
              },
            )
        );
      }
    } catch (error) {
      print("Error getting current location: $error");
    }
  }
}