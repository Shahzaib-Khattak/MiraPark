import 'package:flutter/material.dart';
import 'AddVehicle.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyVehicle extends StatefulWidget {
  final String userId;
  MyVehicle({required this.userId});
  @override
  _MyVehicleState createState() => _MyVehicleState();
}

class _MyVehicleState extends State<MyVehicle> {
  List<Map<String, String>> vehicles = [];

  @override
  void initState() {
    super.initState();
    fetchVehicles(widget.userId);
  }

  Future<void> fetchVehicles(String userId) async {
    final url = Uri.parse('http://mi-park-backend-iota.vercel.app/my-vehicles');

    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 302 || response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          print('Redirecting to $redirectUrl');
          response = await http.post(
            Uri.parse(redirectUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'userId': userId,
            }),
          );
        } else {
          print('Failed to fetch vehicles. Status code: ${response.statusCode}, but no Location header');
          return;
        }
      }

      // Handle the final response
      if (response.statusCode == 200) {
        final List<dynamic> fetchedVehicles = json.decode(response.body);
        setState(() {
          vehicles = fetchedVehicles.map((vehicle) {
            return {
              'vehicleName': vehicle['type'].toString(),
              'plateNumber': vehicle['licensePlate'].toString(),
            };
          }).toList();
        });
        print('Vehicles retrieved: $vehicles');
      } else if (response.statusCode == 404) {
        print('No vehicles found for this user.');
      } else {
        print('Failed to fetch vehicles. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching vehicles: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    Future<void> navigateToAddVehicle() async {
      Map<String, String>? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddVehicle(userId: widget.userId)),
      );

      if (result != null) {
        setState(() {
          vehicles.add(result);
        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            top: -screenHeight * 0.6,
            left: -screenHeight * 0.5,
            right: 0,
            child: FractionallySizedBox(
              widthFactor: 0.4,
              heightFactor: 0.2,
              alignment: Alignment(1.2, 0.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.asset(
                  'assets/MyVehicle.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Foreground content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.transparent,
              padding: EdgeInsets.only(left: 10, top: screenHeight * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    AppLocalizations.of(context)!.myVehicle,
                    style: TextStyle(fontSize: 30),
                  ),
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      AppLocalizations.of(context)!.vehiclethatyouown,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Foreground content
          Positioned(
            bottom: 0,
            top: screenHeight * 0.3,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  colors: [
                    Colors.blue.shade900,
                    Colors.blue.shade800,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenHeight * 0.1),
                  topRight: Radius.circular(screenHeight * 0.1),
                ),
              ),
              padding: EdgeInsets.only(left: 0, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: screenHeight * 0.02,
                      left: screenWidth * 0.1,
                      top: 1,
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        await navigateToAddVehicle();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await navigateToAddVehicle();
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.addaVehicle,
                                  style: TextStyle(color: Colors.white, fontSize: 20),
                                ),
                                Opacity(
                                  opacity: 0.7,
                                  child: Text(
                                    AppLocalizations.of(context)!.addAnewVehicletoyourList,
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(screenHeight * 0.1),
                          topRight: Radius.circular(screenHeight * 0.1),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.00001,
                        horizontal: screenWidth * 0.03,
                      ),
                      child: ListView(
                        physics: BouncingScrollPhysics(),
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                AppLocalizations.of(context)!.yourVehicles,
                                style: TextStyle(fontSize: 25, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                              ),
                              Column(
                                children: vehicles.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, String> vehicle = entry.value;
                                  return _buildVehicleDetail(
                                    index,
                                    vehicle['vehicleName'] ?? '',
                                    vehicle['plateNumber'] ?? '',
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetail(int index, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Dismissible(
      key: Key(index.toString()),
      onDismissed: (direction) {
        setState(() {
          print('Item dismissed at index $index');
          vehicles.removeAt(index);
          print('Updated vehicles list: $vehicles');
        });
      },
      background: Container(
        color: Colors.red,
        alignment: AlignmentDirectional.centerEnd,
        padding: EdgeInsets.only(right: 16.0),
        child: Icon(
          Icons.delete,
          color: Colors.black,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 20, color: textColor),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    vehicles.removeAt(index);
                  });
                },
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ],
      ),
    );
  }
}
