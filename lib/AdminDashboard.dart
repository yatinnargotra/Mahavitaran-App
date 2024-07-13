import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'FullImageScreen.dart';

class AdminDashBoard extends StatefulWidget {
  const AdminDashBoard({Key? key}) : super(key: key);

  @override
  State<AdminDashBoard> createState() => _AdminDashBoardState();
}

class _AdminDashBoardState extends State<AdminDashBoard> {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> _getDescriptionFromMetadata(String imageUrl) async {
    try {
      // Get the reference to the image file
      final ref = _storage.refFromURL(imageUrl);
      // Get the metadata of the file
      final metadata = await ref.getMetadata();
      // Extract the description from the custom metadata
      return metadata.customMetadata?['complaint'];
    } catch (e) {
      print('Error fetching metadata: $e');
      return null;
    }
  }

  void _openLocation(String location) async {
    final url = '$location';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  void _enlargeImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullImageScreen(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No complaints found.'));
          }

          final complaints = snapshot.data!.docs;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final photoUrl = complaint.get('photo_url') as String?;
              final location = complaint.get('location') as String?;

              return FutureBuilder<String?>(
                future: _getDescriptionFromMetadata(photoUrl!),
                builder: (context, snapshot) {
                  final description = snapshot.data;

                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: GestureDetector(
                        onTap: () => _enlargeImage(context, photoUrl!),
                        child: photoUrl != null
                            ? Image.network(photoUrl, width: 50, height: 50, fit: BoxFit.cover)
                            : Icon(Icons.image),
                      ),
                      title: Text('Complaint ${index + 1}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description != null)
                            Text(description),
                          if (location != null)
                            GestureDetector(
                              onTap: () => _openLocation(location),
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
