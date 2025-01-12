import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({Key? key}) : super(key: key);

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Backend URL
  final String backendUrl = 'http://10.10.14.119:5000/find-closest'; // Replace with your IP

  List<Map<String, dynamic>> complaintsWithDistance = [];
  bool sortAscending = true;

  Future<Map<String, dynamic>?> _getMetadata(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();
      print('Metadata fetched for image $imageUrl: ${metadata.customMetadata}');
      return metadata.customMetadata;
    } catch (e) {
      print('Error fetching metadata: $e');
      return null;
    }
  }

  Map<String, double>? _extractCoordinates(String googleMapsUrl) {
    try {
      final uri = Uri.parse(googleMapsUrl);
      final queryParams = uri.queryParameters;
      if (queryParams['query'] != null) {
        final coords = queryParams['query']!.split(',');
        if (coords.length == 2) {
          return {
            'latitude': double.parse(coords[0]),
            'longitude': double.parse(coords[1]),
          };
        }
      }
    } catch (e) {
      print('Error parsing coordinates from URL: $e');
    }
    return null;
  }

  Future<double?> _getDistance(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      print('Missing coordinates: latitude=$latitude, longitude=$longitude');
      return null;
    }

    try {
      print('Sending coordinates to backend: latitude=$latitude, longitude=$longitude');
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final distance = data['distance'] as double;
        return distance;
      } else {
        print('Error fetching nearest location: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> _fetchAndSortComplaints() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: auth.currentUser?.uid)
        .get();

    final complaints = snapshot.docs;

    List<Map<String, dynamic>> tempList = [];

    for (final complaint in complaints) {
      final photoUrl = complaint.get('photo_url') as String?;
      final metadata = await _getMetadata(photoUrl ?? '');
      final googleMapsUrl = metadata?['googleMapsUrl'];
      final complaintText = metadata?['complaint'] ?? 'No description';
      final coordinates = googleMapsUrl != null ? _extractCoordinates(googleMapsUrl) : null;
      final latitude = coordinates?['latitude'];
      final longitude = coordinates?['longitude'];
      final distance = await _getDistance(latitude, longitude);

      // Generate Google Maps URL from latitude and longitude
      final generatedGoogleMapsUrl = (latitude != null && longitude != null)
          ? 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
          : null;

      tempList.add({
        'photoUrl': photoUrl,
        'complaintText': complaintText,
        'distance': distance,
        'generatedGoogleMapsUrl': generatedGoogleMapsUrl, // Add generated URL
      });
    }

    // Sort complaints based on distance
    tempList.sort((a, b) {
      if (sortAscending) {
        return (a['distance'] ?? double.infinity).compareTo(b['distance'] ?? double.infinity);
      } else {
        return (b['distance'] ?? double.infinity).compareTo(a['distance'] ?? double.infinity);
      }
    });

    setState(() {
      complaintsWithDistance = tempList;
    });
  }

  void _toggleSortOrder() {
    setState(() {
      sortAscending = !sortAscending;
      complaintsWithDistance.sort((a, b) {
        if (sortAscending) {
          return (a['distance'] ?? double.infinity).compareTo(b['distance'] ?? double.infinity);
        } else {
          return (b['distance'] ?? double.infinity).compareTo(a['distance'] ?? double.infinity);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAndSortComplaints();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _openGoogleMaps(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: _toggleSortOrder,
            icon: Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.white,
            ),
            tooltip: sortAscending ? 'Sort: Low to High' : 'Sort: High to Low',
          ),
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: complaintsWithDistance.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: complaintsWithDistance.length,
        itemBuilder: (context, index) {
          final complaint = complaintsWithDistance[index];
          final photoUrl = complaint['photoUrl'];
          final complaintText = complaint['complaintText'];
          final distance = complaint['distance'];
          final generatedGoogleMapsUrl = complaint['generatedGoogleMapsUrl'];

          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              leading: photoUrl != null
                  ? Image.network(photoUrl, width: 50, height: 50, fit: BoxFit.cover)
                  : Icon(Icons.image),
              title: Text('Complaint ${index + 1}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complaint: $complaintText'),
                  Text('Distance: ${distance?.toStringAsFixed(2) ?? 'Unknown'} km'),
                  if (generatedGoogleMapsUrl != null)
                    GestureDetector(
                      onTap: () => _openGoogleMaps(generatedGoogleMapsUrl),
                      child: Text(
                        'View on Google Maps',
                        style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
