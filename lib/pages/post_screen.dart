import 'package:flutter/material.dart';
import 'package:social_hub/pages/home.dart';
import 'package:social_hub/widgets/header.dart';
import 'package:social_hub/widgets/post.dart';
import 'package:social_hub/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: postRef.document(userId).collection("userPosts").document(postId).get(),
        builder: (context , snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          Post post = Post.fromDocument(snapshot.data);
          return Center(
            child: Scaffold(
              appBar: header(context, post.description),
              body: ListView(
                children: [
                  Container(
                    child: post,
                  ),
                ],
              ),
            ),
          );
        },
    );
  }
}
