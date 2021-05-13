import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:social_hub/models/user.dart';
import 'package:social_hub/pages/home.dart';
import 'package:social_hub/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final currentUserId;

  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool isLoading = false;
  User user;
  bool _bioValid = true;
  bool _displayValid = true;
  TextEditingController displayName = TextEditingController();
  TextEditingController bio = TextEditingController();

  final _scaffoldkey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldkey,
      appBar: AppBar(
        title: Text("Edit Profile"),
        actions: [
          IconButton(
              icon: Icon(
                Icons.done,
                size: 30,
                color: Colors.green,
              ),
              onPressed: () {
                // await editOnPressed
                Navigator.pop(context);
              }),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: [
                Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 8),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              CachedNetworkImageProvider(currentUser.photoUrl),
                          backgroundColor: Colors.grey,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            buildDisplayNameField(),
                            buildBioNameField(),
                          ],
                        ),
                      ),
                      ElevatedButton(
                          onPressed: updateProfileData,
                          child: Text(
                            "Update Profile",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          )),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: GestureDetector(
                          onTap: () {
                            googleSignIn.signOut();
                            Navigator.pop(context);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            height: MediaQuery.of(context).size.height * .04,
                            width: MediaQuery.of(context).size.width * .34,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await userRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayName.text = user.displayName;
    bio.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            "Display Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextFormField(

          controller: displayName,
          decoration: InputDecoration(
              hintText: "Update Display Name",
            errorText: _displayValid ? null:"Not Valid Display Name",
          ),

        ),
      ],
    );
  }

  buildBioNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            "Update Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextFormField(
          controller: bio,
          decoration: InputDecoration(hintText: "Update Bio",
          errorText: _bioValid ? null:"Bio tooo long",

          ),
        ),
      ],
    );
  }

  void updateProfileData() {
    if(displayName.text.trim().length<3 || displayName.text.isEmpty){
      _displayValid = false;
    }
    if(bio.text.trim().length>100){
      _bioValid = false;
    }
    if(_bioValid && _displayValid)
    {
      userRef.document(widget.currentUserId).updateData({
        "displayName" : displayName.text,
        "bio":bio.text,
      });
      SnackBar snack= SnackBar(content: Text("Profile Updated"));
      ScaffoldMessenger.of(context).showSnackBar(snack);
    }
    else{
      setState(() {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }
  }
}
