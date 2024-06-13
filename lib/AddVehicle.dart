import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class AddVehicle extends StatefulWidget {
  final String userId;
  AddVehicle({required this.userId});
  @override
  _AddVehicleState createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> {
  String _selectedVehicleType = 'luxury car';
  TextEditingController _numberPlateController = TextEditingController();

  Future<void> storeVehicle(String userId, String type, String licensePlate) async {
    final url = Uri.parse('http://mi-park-backend-iota.vercel.app/store-vehicle');
    print('User ID: $userId');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'type': type,
          'licensePlate': licensePlate,
        }),
      );

      if (response.statusCode == 200) {
        print('Vehicle stored successfully');
      } else if (response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          print('Redirecting to $redirectUrl');
          final newUrl = Uri.parse(redirectUrl);
          final redirectResponse = await http.post(
            newUrl,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'userId': userId,
              'type': type,
              'licensePlate': licensePlate,
            }),
          );

          if (redirectResponse.statusCode == 200) {
            print('Vehicle stored successfully after redirect');
          } else {
            print('Failed to store vehicle after redirect. Status code: ${redirectResponse.statusCode}');
          }
        } else {
          print('Failed to store vehicle. Status code: 308, but no Location header');
        }
      } else {
        print('Failed to store vehicle. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error storing vehicle: $error');
    }
  }

  List<String> _vehicleTypes = [
    'luxury car',
    'SUV',
    'Subcompact car',
    'KIA Sportage',
    'Opel Insigna',
    'KIA Ceed',
    'Compact Car',
    'Mid Size Car',
    'Opel Zafira',
    'Opel Meriva',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Vehicle'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              items: _vehicleTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleType = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            TextFormField(
              controller: _numberPlateController,
              decoration: InputDecoration(
                labelText: 'Car Number Plate',
                hintText: 'Format: AB-1234-CD',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                storeVehicle(widget.userId, _selectedVehicleType, _numberPlateController.text);
                Navigator.pop(context, {'Vehicle Name': _selectedVehicleType, 'Plate Number': _numberPlateController.text});
              },
              child: Text('Save Vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numberPlateController.dispose();
    super.dispose();
  }
}
