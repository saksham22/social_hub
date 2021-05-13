import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_hub/pages/home.dart';
import 'package:social_hub/widgets/header.dart';
import 'package:social_hub/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;
class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({this.postId, this.postOwnerId, this.postMediaUrl});
  @override
  CommentsState createState() => CommentsState(
      postId:postId,
      postOwnerId:postOwnerId,
      postMediaUrl:postMediaUrl
  );
}

class CommentsState extends State<Comments> {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
  TextEditingController cmt = TextEditingController();
  CommentsState({this.postId, this.postOwnerId, this.postMediaUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, "Comments"),
      body: Column(
        children: [
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: cmt,
              decoration: InputDecoration(
                labelText: "Write a comment",
              ),
            ),
            trailing: OutlinedButton(
              onPressed: addComment,
              child: Text("Post"),
            ) ,
          ),
        ],
      ),
    );
  }

  buildComments() {
    return StreamBuilder(
        stream: commentsRef.document(postId).collection("comments").orderBy("timestamp",descending: false).snapshots(),
        builder: (context,snapshot){
      if(!snapshot.hasData){
        return circularProgress();
      }
      List<Comment> cmts=[];
      snapshot.data.documents.forEach((doc){
        cmts.add(Comment.fromDocument(doc));
      });
      return ListView(
        children: cmts,
      );

        }
    );
  }

  void addComment() {
    commentsRef.document(postId).collection("comments").add({
      "username":currentUser.username,
      "comment":cmt.text,
      "timestamp":DateTime.now(),
      "avatarUrl":currentUser.photoUrl,
      "userId":currentUser.id,
    });
    if(postOwnerId!=currentUser.id){
      activityFeedRef.document(postOwnerId).collection("feedItems").add({
        "type":"comment",
        "commentData":cmt.text,
        "username":currentUser.username,
        "userId":currentUser.id,
        "userProfileImg":currentUser.photoUrl,
        "postId":postId,
        "mediaUrl":postMediaUrl,
        "timestamp":DateTime.now(),
      });
    }
    cmt.clear();
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String comment;
  final Timestamp timestamp;
  final String avatarUrl;
  final String userId;
  Comment({
    this.username,
    this.comment,
    this.timestamp,
    this.avatarUrl,
    this.userId,
  });
  factory Comment.fromDocument(DocumentSnapshot doc){
    return Comment(
      username:doc['username'],
      comment:doc['comment'],
      timestamp:doc['timestamp'],
      avatarUrl:doc['avatarUrl'],
      userId:doc['userId'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),

        ),
        Divider(),
      ],
    );
  }
}
