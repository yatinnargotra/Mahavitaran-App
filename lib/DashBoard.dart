import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'Home.dart'; // Import the Home page

class DashBoard extends StatefulWidget {
  const DashBoard({Key? key}) : super(key: key);

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

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

  // Function to handle logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: auth.currentUser?.uid)
            .snapshots(),
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
                      leading: photoUrl != null
                          ? Image.network(photoUrl, width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.image),
                      title: Text('Complaint ${index + 1}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description != null) Text(description),
                          if (location != null) Text(location, style: TextStyle(color: Colors.blue)),
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
