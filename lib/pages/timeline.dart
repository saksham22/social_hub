import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_hub/models/user.dart';
import 'package:social_hub/pages/home.dart';
import 'package:social_hub/widgets/header.dart';
import 'package:social_hub/widgets/post.dart';
import 'package:social_hub/widgets/progress.dart';




class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
 // List <dynamic> users=[];
  List<Post> posts;
  @override
  void initState() {
    // getUsers();
    // getUsersById();
    super.initState();
    getTimeLine();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context,"Social Hub"),
      body:RefreshIndicator(
        onRefresh: () async => getTimeLine(),
        child: buildTimeLine(),
      ),

    );
  }

void getTimeLine() async{
QuerySnapshot snapshot= await timelineRef.document(currentUser.id).collection("timelinePosts").orderBy('timestamp',descending: true).getDocuments();
List<Post> post = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
setState(() {
  posts=post;
});

}

  buildTimeLine() {
    if(posts==null){
      return circularProgress();
    }
    else if(posts.isEmpty){
      return Text("No Posts");
    }
    return ListView(children: posts,);
  }


  // void getUsers() async {
  //  //complex queries requires indexing
  //   // final QuerySnapshot snapshot =await  userRef
  //   //     .where("postsCount",isGreaterThan: -1)
  //   //     .where("isAdmin",isEqualTo: true)
  //   //     .getDocuments();
  //   final QuerySnapshot snapshot =await  userRef.getDocuments();
  //     setState(() {
  //       users = snapshot.documents;
  //     });
  //   }
  //
  // getUsersById() async {
  //   DocumentSnapshot doc =  await userRef.document("4DoWkiMVNu23vF6rMlZd").get();
  //   print(doc.data);
  // }



}

