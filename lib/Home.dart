import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myloginpage/DashBoard.dart';
import 'package:myloginpage/login.dart';
import 'HomeScreen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Enable virtual display for Android webview.
    if (WebView.platform == null) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mahavitaran Help',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.green,
          child: ListView(
            children: [
              DrawerHeader(
                child: Image.asset(
                  'assets/logo3.png',
                  fit: BoxFit.contain,
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text(
                  'Complaint',
                  style: TextStyle(fontSize: 20),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => CameraPage()));
                },
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 20),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => DashBoard()));
                },
              ),
              Divider(), // Divider line
              ListTile(
                leading: Icon(Icons.logout),
                title: Text(
                  'Logout',
                  style: TextStyle(fontSize: 20),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
      body: WebView(
        initialUrl: 'https://www.mahadiscom.in/en/news-latest-announcements/',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
