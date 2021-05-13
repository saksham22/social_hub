import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_hub/models/user.dart';
import 'package:social_hub/pages/activity_feed.dart';
import 'package:social_hub/pages/create_account.dart';
import 'package:social_hub/pages/profile.dart';
import 'package:social_hub/pages/search.dart';
import 'package:social_hub/pages/timeline.dart';
import 'package:social_hub/pages/upload.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection('users');
final postRef = Firestore.instance.collection("posts");
final commentsRef = Firestore.instance.collection("comments");
final activityFeedRef = Firestore.instance.collection("feed");
final followRef = Firestore.instance.collection("following");
final followersRef = Firestore.instance.collection("followers");
final timelineRef = Firestore.instance.collection("timeline");
final StorageReference storageRef = FirebaseStorage.instance.ref();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
 int pageIndex=0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  // set pageIndex(int pageIndex) {}
  @override
  void initState() {
    super.initState();
    pageController = PageController();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    // Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
    pageIndex=0;

  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      print('User signed in!: $account');
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  @override
  void dispose(){
    pageController.dispose();
    super.dispose();
  }
  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }
  onPageChanges(int pageIndex){
    setState(() {
      this.pageIndex = pageIndex;
    });
  }
  onTap(int pageIndex){
    pageController.jumpToPage(pageIndex);
    // pageController.animateToPage(
    //b
    //     pageIndex,
    //   duration: Duration(milliseconds: 200),
    //   curve: Curves.easeIn
    // );
  }
  Widget buildAuthScreen1() {
    // ignore: deprecated_member_use
    return RaisedButton(
      child: Text('Logout'),
      onPressed: logout,
    );
  }
  Scaffold buildAuthScreen(){
    return Scaffold(
      key:_scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser,),
          ActivityFeed(),
          Upload(),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanges,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor ,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot),),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera,size: 36,)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'SocialHub ',
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 90.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }

  void createUserInFirestore() async{
    //check if user exists
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc =await userRef.document(user.id).get();
    //if doesnt exists then create account page
    if(!doc.exists){
     final username= await Navigator.push(context, MaterialPageRoute(builder: (context)=>CreateAccount()));
     userRef.document(user.id).setData({
       "id": user.id,
       "username":username,
       "photoUrl":user.photoUrl,
       "email":user.email,
       "displayName":user.displayName,
       "bio":"",
       "timestamp":DateTime.now(),
     });
     doc = await userRef.document(user.id).get();
    }
    //get user name from create account use it to make new user document
    currentUser = User.fromDocument(doc);
    print(currentUser);
    print(currentUser.displayName);
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiOSPermission();

    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token\n");
      userRef
          .document(user.id)
          .updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification shown!");
          SnackBar snackbar = SnackBar(
              content: Text(
                body,
                overflow: TextOverflow.ellipsis,
              ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notification NOT shown");
      },
    );
  }

  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }
}


