import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;




const kGoogleApiKey = 'AIzaSyBUtjCUeiVXJzek8eh30P7feb_dGLEVVjc';

class CombinedScreen extends StatefulWidget {
  final String userId;

  CombinedScreen({required this.userId});
  @override
  _CombinedScreenState createState() => _CombinedScreenState();
}
// Widget offerCard(String title, String subtitle, String price, String duration, int distance) {
//   return ListTile(
//     title: Text(title),
//     subtitle: Text(subtitle),
//     trailing: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: <Widget>[
//         Text(price, style: TextStyle(color: Colors.blue, fontSize: 16)),
//         Text(duration, style: TextStyle(color: Colors.grey, fontSize: 12)),
//       ],
//     ),
//     leading: Icon(Icons.my_location),
//     onTap: () {
//       // Action on tap
//     },
//   );
// }


class _CombinedScreenState extends State<CombinedScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  double containerPosition = 0.0; // Initial position
  double containerHeight = 100.0; // Initial height
  bool isContainerOpen = false; // Initial state
  bool isReserved = false; // Change this to false if the point is not reserved
  late BitmapDescriptor? customIcon;

  Future<BitmapDescriptor> _getResizedBitmapDescriptor(String asset, int width, int height) async {
    final ByteData data = await rootBundle.load(asset);
    final Uint8List bytes = data.buffer.asUint8List();
    img.Image image = img.decodeImage(bytes)!;
    img.Image resizedImage = img.copyResize(image, width: width, height: height);

    final ui.Codec codec = await ui.instantiateImageCodec(
      Uint8List.fromList(img.encodePng(resizedImage)),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(resizedBytes);
  }






  // String getMarkerTitle() {
  //   return isReserved ? 'Booked' : 'Free';
  // }
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

  Future<void> _displayBottomSheet(BuildContext context, String markerTitle, LatLng markerPosition, LatLng userLocation, double distance, {required String euid, required String username}) {
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
              AppLocalizations.of(context)!.yourvehicleswillbeparkedhere,

              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white
                    : Colors.grey.withOpacity(0.3),
                fontSize: 12,

              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('${distance.toStringAsFixed(2)} Km', "assets/Location.png"),
                _buildInfoItem(AppLocalizations.of(context)!.spots, "assets/app_icon.png"),
                _buildInfoItem("€5/hour", "assets/Euro.png"),
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
                        distance: distance.toStringAsFixed(2), licensePlate: '', StartTime: '', EndTime: '', euid: euid, username: username
                      ),
                    ),
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenHeight * 0.1),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.booknow,
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
    _loadCustomMarker();

  }
  void _loadCustomMarker() async {
    customIcon = await _getResizedBitmapDescriptor(
      'assets/app_icon.png', // Path to your custom image
      50, // Width in pixels
      50, // Height in pixels
    );
    setState(() {});
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
              label: const Text('Current Location'),
              icon: const Icon(Icons.my_location),
            ),
          ),
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   right: 0,
          //   child: GestureDetector(
          //     onVerticalDragUpdate: (details) {
          //       setState(() {
          //         // Update the container height based on user drag
          //         containerHeight += details.primaryDelta!;
          //         containerHeight = containerHeight.clamp(100.0, MediaQuery.of(context).size.height);
          //       });
          //     },
          //     onVerticalDragEnd: (details) {
          //       setState(() {
          //         // Determine if the container should open or close based on the drag direction
          //         isContainerOpen = details.primaryVelocity! < 0;
          //         if (!isContainerOpen) {
          //           // Reset to initial height if dragging down and container is closing
          //           containerHeight = 100.0;
          //         }
          //       });
          //     },
          //     child: AnimatedContainer(
          //       duration: Duration(milliseconds: 300),
          //       curve: Curves.easeInOut,
          //       height: isContainerOpen ? MediaQuery.of(context).size.height : containerHeight,
          //       color: Colors.white,
          //       child: Column(
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         children: <Widget>[
          //           Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               Icon(Icons.arrow_drop_up),
          //               Text(
          //                 "Offers near You",
          //                 style: TextStyle(
          //                   fontSize: 18,
          //                   fontWeight: FontWeight.w400,
          //                 ),
          //               ),
          //             ],
          //           ),
          //           Expanded(
          //             child: ListView(
          //               children: <Widget>[
          //                 offerCard("Night ticket", "Park One im Mona Einkaufsz...", "8.00 €", "14 hrs", 5257),
          //                 offerCard("1 week ticket", "Park One im Mona Einkaufsz...", "45.00 €", "7 days", 5257),
          //                 offerCard("2-Weeks-ticket", "Park One im Mona Einkaufsz...", "80.00 €", "14 days", 5257),
          //                 offerCard("One month ticket", "Park One im Mona Einkaufsz...", "155.00 €", "30 days", 5257),
          //                 offerCard("Short-term Parking Ti...", "Park One im Carré Fürther Fr...", "2.50 €", "60 min", 5283),
          //                 offerCard("Day ticket", "Parkgarage Hochzoller Mitte", "5.00 €", "24 hrs", 5283),
          //               ],
          //             ),
          //           ),
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
            icon: customIcon ?? BitmapDescriptor.defaultMarker, // Use custom icon or default marker
            infoWindow: InfoWindow(title: 'Islamabad, Pakistan'),
            onTap: () {
              if (!isReserved) {
                _displayBottomSheet(context, 'Islamabad, Pakistan', LatLng(33.6844 , 73.0479), userLocation, distance, euid: 'eui-70b3d57ed8003056', username: 'raza242424@miraee');
              }
            },
          ),


        );
        _markers.add(
          Marker(
            markerId: MarkerId('123456'),
            position: LatLng(54.334760, 10.119170),
            icon: customIcon ?? BitmapDescriptor.defaultMarker, // Use custom icon or default marker
            infoWindow: InfoWindow(title: 'KITZ GmbH'),
            onTap: () {
              if (!isReserved) {
                _displayBottomSheet(context, 'KITZ GmbH', LatLng(54.334760, 10.119170), userLocation, distance, euid: 'eui-0080e115000add43', username: 'raza242424@miraee');
              }
            },
          ),
        );
        setState(() {});
      }
    } catch (error) {
      print("Error getting current location: $error");
    }
  }
}