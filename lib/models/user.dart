import 'package:cloud_firestore/cloud_firestore.dart';

class User {

  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String bio;
  final String displayName;

  User({
    this.id,
    this.username,
    this.email,
    this.photoUrl,
    this.bio,
    this.displayName,
});


factory User.fromDocument(DocumentSnapshot doc){
  return User(
    id: doc['id'],
    username:doc['username'],
    photoUrl:doc['photoUrl'],
    email:doc['email'],
    displayName:doc['displayName'],
    bio:doc['bio'],
  );

}
}
