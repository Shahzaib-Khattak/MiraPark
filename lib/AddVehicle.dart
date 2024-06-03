import 'package:flutter/material.dart';

class AddVehicle extends StatefulWidget {
  @override
  _AddVehicleState createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> {
  String _selectedVehicleType = 'luxury car';
  TextEditingController _numberPlateController = TextEditingController();

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
                String vehicleType = _selectedVehicleType;
                String numberPlate = _numberPlateController.text;

                // Pass the data back to the previous screen
                Navigator.pop(context, {'Vehicle Name': vehicleType, 'Plate Number': numberPlate});
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
