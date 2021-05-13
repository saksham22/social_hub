// import 'dart:js';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_hub/pages/home.dart';
import 'package:social_hub/pages/post_screen.dart';
import 'package:social_hub/pages/profile.dart';
import 'package:social_hub/widgets/header.dart';
import 'package:social_hub/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: header(context, "Activity Feed"),
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context, snapshot){
            if(!snapshot.hasData){
              return circularProgress();
            }
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }

  getActivityFeed() async{
    QuerySnapshot querySnapshot =await activityFeedRef.document(currentUser.id).collection("feedItems").orderBy("timestamp",descending: true).limit(50).getDocuments();
    List<ActivityFeedItem> feedItems =[];


    querySnapshot.documents.forEach((element)
    {
      // print('ITEMS are ${element.data}');
      feedItems.add(ActivityFeedItem.fromDocument(element));
    });
    return feedItems;
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final String ownerId;
  final Timestamp timestamp;

  ActivityFeedItem({this.username, this.userId, this.type, this.mediaUrl, this.postId, this.userProfileImg, this.commentData, this.timestamp,this.ownerId});

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
        username:doc['username'],
        userId:doc['userId'],
        type:doc['type'],
        mediaUrl:doc['mediaUrl'],
        postId:doc['postId'],
        userProfileImg:doc['userProfileImg'],
        commentData:doc['commentData'],
        timestamp:doc['timestamp'],
        ownerId: doc['ownerId'],
    );
  }
  configureMediaPreview(context){
     if(type=='like'||type =='comment'){
       mediaPreview = GestureDetector(
         onTap: (){showPost(context);},
         child: Container(
           height: 50,
           width: 50,
           child: AspectRatio(
             aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(mediaUrl),
                  )
                ),
              ),
           ),
         ),
       );
     }
     else{
       mediaPreview = Text('');
     }
     if(type=='like'){
       activityItemText = "liked your post";
     }
     else if(type=='follow'){
       activityItemText = "is following you";
     }
     else if(type=='comment'){
       activityItemText = "replied: $commentData";
     }
     else{
       activityItemText = "ERROR:Unknown Type $type";
     }
  }
  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(padding: EdgeInsets.only(bottom: 2),
    child: Container(
      color: Colors.white54,
      child: ListTile(
        title: GestureDetector(
          onTap: ()=>showProfile(context,profileId: userId),
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: username,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' $activityItemText',
                ),
              ]
            ),
          ),
        ),
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(userProfileImg),
      ),
        subtitle: Text(
          timeago.format(timestamp.toDate()),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: mediaPreview,
      ),
    ),
    );
  }

   showPost(context) {
    Navigator.push(context, MaterialPageRoute(builder: (context)=>PostScreen(postId: postId,userId: ownerId,)));
   }

   showProfile(BuildContext context,{String profileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(profileId: profileId,)));
   }

}
