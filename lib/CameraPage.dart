import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'DashboardPage.dart'; // Adjust the import based on actual file location
import 'MapPage.dart'; // Adjust the import based on actual file location

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;
  LatLng? _manualLocation;
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras[0], // Use cameras[0] or any appropriate camera index
      ResolutionPreset.max,
    );

    await _cameraController?.initialize();
    if (mounted) {
      setState(() {}); // Trigger a rebuild after camera is initialized
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final newPath = path.join(
        path.dirname(image.path),
        '${path.basenameWithoutExtension(image.path)}.jpg',
      );

      final newFile = await File(image.path).rename(newPath);

      LatLng? location = _manualLocation ?? await _getCurrentLocation();

      if (location != null) {
        String imageURL = await _uploadImageToStorage(newFile.path);
        await _saveComplaintToFirestore(imageURL, location);

        // Navigate to dashboard after saving complaint
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      } else {
        print('Failed to get location');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String> _uploadImageToStorage(String filePath) async {
    File file = File(filePath);
    try {
      TaskSnapshot snapshot = await _storage
          .ref('complaints/${DateTime.now().toIso8601String()}.jpg')
          .putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print(e);
      return '';
    }
  }

  Future<void> _saveComplaintToFirestore(String imageURL, LatLng location) async {
    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'description': _descriptionController.text.trim(),
        'photoURL': imageURL,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Complaint saved to Firestore');
    } catch (e) {
      print('Error saving complaint: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final newPath = path.join(
          path.dirname(pickedFile.path),
          '${path.basenameWithoutExtension(pickedFile.path)}.jpg',
        );

        final newFile = await File(pickedFile.path).rename(newPath);

        LatLng? location = _manualLocation ?? await _getCurrentLocation();

        if (location != null) {
          String imageURL = await _uploadImageToStorage(newFile.path);
          await _saveComplaintToFirestore(imageURL, location);

          // Navigate to dashboard after saving complaint
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        } else {
          print('Failed to get location');
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return LatLng(position.latitude, position.longitude);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  Future<void> _selectLocationOnMap() async {
    LatLng selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPage()),
    );
    setState(() {
      _manualLocation = selectedLocation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Page'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Enter description...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            Center(
              child: _cameraController != null &&
                  _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : SizedBox(),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _takePicture,
                  child: Icon(Icons.camera_alt),
                ),
                SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: _pickImageFromGallery,
                  child: Icon(Icons.photo),
                ),
                SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: _selectLocationOnMap,
                  child: Icon(Icons.map),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
