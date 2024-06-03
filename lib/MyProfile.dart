import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Login_Screen.dart';
import 'package:image_picker/image_picker.dart';


class ProfileScreen extends StatefulWidget {
  final String userId; // Define the userId parameter

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = '';
  String email = '';
  String phoneNumber = '';
  String password = '';
  File? _image;

  @override
  void initState() {
    super.initState();
    fetchData();
    print('User ID: ${widget.userId}');
  }

  Future<void> fetchData() async {
    print('Fetching data for user ID: ${widget.userId}');
    try {
      var response = await http.post(
        Uri.parse('http://mi-park-backend-iota.vercel.app/user-details'), // Replace with your backend URL
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'userId': widget.userId,
        }),
      );

      // Follow redirects until we get a non-308 response
      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];

        // Make another POST request to the redirect URL
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, String>{
            'userId': widget.userId,
          }),
        );
      }

      // Now check the final response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          fullName = responseData['fullName'];
          email = responseData['email'];
          phoneNumber = responseData['phone'];
        });
      } else {
        // Handle error scenario
        print('Error fetching user details: ${response.reasonPhrase}');
      }
    } catch (error) {
      // Handle error scenario
      print('Error fetching user details: $error');
    }
  }


  Future<void> _uploadPhoto(File imageFile) async {
    try {
      final url = Uri.parse('http://mi-park-backend-iota.vercel.app/upload-photo'); // Replace with your backend URL
      var request = http.MultipartRequest('POST', url)
        ..fields['userId'] = widget.userId
        ..files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

      var response = await http.Response.fromStream(await request.send());

      // Follow redirects until we get a non-308 response
      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];

        // Make another POST request to the redirect URL
        response = await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, String>{
            'userId': widget.userId,
          }),
        );
      }

      if (response.statusCode == 200) {
        print('Profile photo uploaded successfully');
      } else {
        print('Error uploading profile photo: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error uploading profile photo: $error');
    }
  }


  Future<void> _uploadImageToServer() async {
    try {
      // Create multipart request for uploading image
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://mi-park-backend-iota.vercel.app/upload-photo'),
      );

      // Add image file to the request
      request.files.add(
        await http.MultipartFile.fromPath('photo', _image!.path),
      );

      // Send the request
      var response = await request.send();

      // Follow redirects until we get a non-308 response
      while (response.statusCode == 308) {
        var redirectUrl = response.headers['location'];

        // Make another POST request to the redirect URL
        response = (await http.post(
          Uri.parse(redirectUrl ?? ''),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, String>{
            'userId': widget.userId,
          }),
        )) as http.StreamedResponse;
      }

      // Check if request was successful
      if (response.statusCode == 200) {
        print('Image uploaded successfully');
      } else {
        print('Failed to upload image: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error uploading image: $error');
    }
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });

      // Call function to upload image to server
      await _uploadImageToServer();
    } else {
      // Handle the case where the user cancels image selection
      print('No image selected.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context
            ).pop();
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: <Widget>[
          Center(
            child: GestureDetector(
              onTap: () async {

                await _getImage();
                if (_image != null) {
                  await _uploadPhoto(_image!);
                }
              },
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null ? FileImage(_image!) : null,
              ),
            ),
          ),
          ListTile(
            title: Text('Full Name'),
            subtitle: Text(fullName),
          ),
          ListTile(
            title: Text('Email Address'),
            subtitle: Text(email),
          ),
          ListTile(
            title: Text('Phone Number'),
            subtitle: Text(phoneNumber),
          ),
        ],
      ),
    );
  }

}
