import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_hub/pages/home.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((value) => print("Time stamps Enabled"),onError: ()=>print("Error"));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterShare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      home: Home(),
    );
  }
}