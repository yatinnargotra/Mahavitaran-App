import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myloginpage/DashBoard.dart';
import 'package:path/path.dart' as path;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;
  LatLng? _manualLocation;
  TextEditingController _descriptionController = TextEditingController();
  String? _selectedProblem;
  bool _isOtherSelected = false;

  final List<String> _problems = [
    'Sparking / स्पार्किंग',
    'Conductor Snapping / कंडक्टर तुटणे',
    'Box Open / बॉक्स उघडा',
    'No Doors / दरवाजे नाहीत',
    'Electrical Noise and Interference / विद्युत आवाज आणि हस्तक्षेप',
    'Corrosion and Environmental Damage / गंज आणि पर्यावरणीय नुकसान',
    'Animal Interference / प्राण्यांचा हस्तक्षेप',
    'Unauthorised Person Seen near Pole or Transformer / खांब किंवा ट्रान्सफॉर्मरजवळ अनधिकृत व्यक्ती दिसली',
    'Climber on Pole or Transformer / खांब किंवा ट्रान्सफॉर्मरवर चढणारा',
    'No Guarding or Broken Guarding / संरक्षण नाही किंवा तुटलेले संरक्षण',
    'Others / इतर'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize camera only when the capture button is pressed
    // _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Find the rear camera
    CameraDescription? rearCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        rearCamera = camera;
        break;
      }
    }

    if (rearCamera != null) {
      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController?.initialize();
      if (mounted) {
        setState(() {}); // Trigger a rebuild after camera is initialized
      }
    } else {
      print('No rear camera found');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } else {
      return null;
    }
  }

  // Function to handle logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
  }

  Future<void> _takePicture() async {
    // Initialize camera only when the capture button is pressed
    if (_cameraController == null) {
      await _initializeCamera();
    }

    if (_cameraController?.value.isInitialized ?? false) {
      try {
        // Take the picture
        final image = await _cameraController!.takePicture();
        final newPath = path.join(
          path.dirname(image.path),
          '${path.basenameWithoutExtension(image.path)}.jpg',
        );

        final newFile = await File(image.path).rename(newPath);
        print(newFile.path);

        // If manual location is set, use it; otherwise, get the current location
        LatLng? location = _manualLocation ?? await _getLatLngFromPosition(await _getCurrentLocation());

        if (location != null) {
          // Upload the image to Firebase Storage with location metadata
          await _uploadToFirebase(newFile.path, location);
          // Navigate to DashBoard after successful upload
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => DashBoard()),

          );
        } else {
          print('Failed to get location');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Pick an image from the gallery
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final newPath = path.join(
          path.dirname(pickedFile.path),
          '${path.basenameWithoutExtension(pickedFile.path)}.jpg',
        );

        final newFile = await File(pickedFile.path).rename(newPath);
        print(newFile.path);

        // If manual location is set, use it; otherwise, get the current location
        LatLng? location = _manualLocation ?? await _getLatLngFromPosition(await _getCurrentLocation());

        if (location != null) {
          // Upload the image to Firebase Storage with location metadata
          await _uploadToFirebase(newFile.path, location);
          // Navigate to DashBoard after successful upload
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => DashBoard()),
                (route) => false,
          );
        } else {
          print('Failed to get location');
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<LatLng?> _getLatLngFromPosition(Position? position) async {
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    } else {
      return null;
    }
  }

  Future<void> _uploadToFirebase(String filePath, LatLng location) async {
    File file = File(filePath);
    try {
      // Create a Google Maps URL from the latitude and longitude
      String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';

      // Create a metadata object with custom metadata
      SettableMetadata metadata = SettableMetadata(customMetadata: {
        'googleMapsUrl': googleMapsUrl,
        'complaint': _isOtherSelected
            ? (_descriptionController.text.isNotEmpty ? _descriptionController.text : 'No description provided')
            : (_selectedProblem ?? 'No problem selected'),
      });

      // Upload image to Firebase Storage
      TaskSnapshot snapshot = await _storage.ref('complaints/${DateTime.now().toIso8601String()}.jpg')
          .putFile(file, metadata);

      // Get download URL
      String downloadURL = await snapshot.ref.getDownloadURL();
      final User? user = auth.currentUser;
      final uid = user?.uid;

      await FirebaseFirestore.instance.collection('users').add({
        'uid': uid,
        'photo_url': downloadURL,
        'location': googleMapsUrl,
        // 'username' : userData.data()!['username'],
      });

      print('Uploaded to Firebase Storage: $downloadURL');
    } on FirebaseException catch (e) {
      print(e);
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
        title: Text(
          'Mahavitaran Help', // Changed title to "Mahavitaran Help"
          style: TextStyle(color: Colors.white), // Changed text color to white
        ),
        backgroundColor: Colors.green, // Changed app bar background color to green
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Select problem...',
                border: OutlineInputBorder(),
              ),
              items: _problems.map((String problem) {
                return DropdownMenuItem<String>(
                  value: problem,
                  child: Text(problem),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProblem = newValue;
                  _isOtherSelected = newValue == 'Others / इतर';
                });
              },
              value: _selectedProblem,
            ),
            if (_isOtherSelected) ...[
              SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Enter description...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSubmitted: (_) {
                  FocusScope.of(context).unfocus(); // Dismiss the keyboard
                },
              ),
            ],
            SizedBox(height: 20),
            Center(
              child: _cameraController != null && _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : SizedBox(), // Use SizedBox or another widget when camera is not initialized
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _takePicture,
                  child: Icon(Icons.camera_alt),
                  backgroundColor: Colors.green, // Set background color to green
                ),
                SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: _pickImageFromGallery,
                  child: Icon(Icons.photo),
                  backgroundColor: Colors.green, // Set background color to green
                ),
                SizedBox(width: 20),
                FloatingActionButton(
                  onPressed: _selectLocationOnMap,
                  child: Icon(Icons.map),
                  backgroundColor: Colors.green, // Set background color to green
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = LatLng(37.42796133580664, -122.085749655962);
  LatLng _selectedPosition = LatLng(37.42796133580664, -122.085749655962);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, _selectedPosition);
            },
            icon: Icon(Icons.check),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: {
          Marker(
            markerId: MarkerId('selected-location'),
            position: _selectedPosition,
            draggable: true,
            onDragEnd: (LatLng position) {
              setState(() {
                _selectedPosition = position;
              });
            },
          ),
        },
        onTap: (LatLng position) {
          setState(() {
            _selectedPosition = position;
          });
        },
      ),
    );
  }
}
