import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_hub/models/user.dart';
import 'package:social_hub/pages/comments.dart';
import 'package:social_hub/pages/home.dart';
import 'package:social_hub/pages/profile.dart';
import 'package:social_hub/widgets/progress.dart';
import 'dart:async';
import 'custom_image.dart';
import 'package:flutter/animation.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({this.postId, this.ownerId, this.username, this.location, this.description, this.mediaUrl, this.likes});
  factory Post.fromDocument(DocumentSnapshot doc){
    return Post(
        postId:doc['postId'],
        ownerId:doc['ownerId'],
        username:doc['username'],
        location:doc['location'],
        description:doc['description'],
        mediaUrl: doc['mediaUrl'],
        likes: doc['likes'],
    );

  }
  int getLikeCount(likes){
    if(likes == null){
      return 0;
    }
    int count = 0;
    likes.values.forEach((val){
      if(val ==true){
        count++;
      }

    });
    return count;
  }
  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId:this.ownerId,
    username:this.username,
    location:this.location,
    description:this.description,
    mediaUrl:this.mediaUrl,
    likes: this.likes,
    likeCount:getLikeCount(this.likes),
  );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  Map likes;
  int likeCount;
  bool isLiked;
  bool showHeart = false;
  _PostState({this.postId, this.ownerId, this.username, this.location, this.description, this.mediaUrl, this.likes, this.likeCount});
  @override
  Widget build(BuildContext context) {
    isLiked = likes[currentUserId] == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],

    );
  }

  buildPostHeader() {
    return FutureBuilder(
        future: userRef.document(ownerId).get(),
        builder: (context, snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          bool isPostOwner = currentUserId==ownerId;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              backgroundColor: Colors.grey,
            ),
            title: GestureDetector(
              onTap: ()=>showProfile(context,profileId: user.id),
              child: Text(
                user.username,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            subtitle: Text(location),
            trailing: isPostOwner? IconButton(
              onPressed: ()=>handleDeletePost(context),
              icon: Icon(Icons.more_vert),
            ):Text(""),
          );
        }
    );
  }
  showProfile(BuildContext context,{String profileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(profileId: profileId,)));

  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image.network(mediaUrl),
          Container(
            // height: MediaQuery.of(context).size.height*.7,
            // width: MediaQuery.of(context).size.width*.99 ,
            child: cachedNetworkImage(mediaUrl),


          ),
          // TODO:Use flutter animation and get the heart beating!!!
          // showHeart ? Animator(
          //   duration: Duration(milliseconds: 300),
          //   tween: Tween(begin: 0.8,end: 1.4),
          //   curve: Curves.elasticOut,
          //   cycles: 0,
          //   builder: (context , animatorState)=>,
          // )
          //     : Text(""),

          showHeart ? Icon(Icons.favorite,size: 80,color: Colors.red,):Text(""),

        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(padding: EdgeInsets.only(top: 40,left: 20)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked?Icons.favorite: Icons.favorite_border,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20)),
            GestureDetector(
              onTap: ()=> showComments(
                context,
                postId:postId,
                ownerId:ownerId,
                mediaUrl:mediaUrl
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.blue[900],
              ),
            ),

          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$likeCount likes",
                style: TextStyle(color: Colors.black,
                fontWeight: FontWeight.bold,
                ),

              ),

            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$username",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(description),
            ),
          ],
        ),
      ],
    );
  }
  handleLikePost(){
    bool _isLiked = likes[currentUserId] == true;
    if(_isLiked){
      postRef.document(ownerId).collection('userPosts').document(postId).updateData({'likes.$currentUserId':false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -=1;
        isLiked = false;
        likes[currentUserId]=false;
      });
    }
    else if(!_isLiked){
      postRef.document(ownerId).collection('userPosts').document(postId).updateData({'likes.$currentUserId':true});
      addLiketoActivityFeed();
      setState(() {
        likeCount +=1;
        isLiked = true;
        likes[currentUserId]=true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500),(){
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  showComments(BuildContext context, {String postId, String ownerId, String mediaUrl}) {
    Navigator.push(context, MaterialPageRoute(builder: (context){
      return Comments(
          postId:postId,
          postOwnerId:ownerId,
          postMediaUrl:mediaUrl
      );
    }));
  }

  void addLiketoActivityFeed() {
    if(currentUserId!=ownerId){

      activityFeedRef.document(ownerId).collection("feedItems").document(postId).setData({
        "type":"like",
        "ownerId":ownerId,
        "username":currentUser.username,
        "userId":currentUser.id,
        "userProfileImg":currentUser.photoUrl,
        "postId":postId,
        "mediaUrl":mediaUrl,
        "timestamp":DateTime.now(),
      });
    }

  }

  void removeLikeFromActivityFeed() {
    if (currentUserId != ownerId) {
      activityFeedRef.document(ownerId).collection("feedItems")
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  handleDeletePost(BuildContext Pcontext) {
    return showDialog(
      context: Pcontext,
      builder: (context){
        return SimpleDialog(
          title: Text("Remove this post?"),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                // bool loading=false;
                // if(!loading){
                //
                // }
                await deletePost();
              } ,
              child: Text('Delete',style: TextStyle(color: Colors.red),),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancle'),
            ),
          ],
        );
      }
    );
  }

  Future<bool> deletePost() async{
    postRef.document(ownerId).collection('userPosts').document(postId).get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
    storageRef.child("post_$postId.jpg").delete();
    //then delete all activity feed notifications
    QuerySnapshot activity=await activityFeedRef.document(ownerId).collection("feedItems").where('postId',isEqualTo: postId).getDocuments();
    activity.documents.forEach((element) {if(element.exists){
      element.reference.delete();
    }
    });
    QuerySnapshot comments = await commentsRef.document(postId).collection('comments').getDocuments();
    comments.documents.forEach((element) {if(element.exists){
      element.reference.delete();
    }
    });
  return true;
  }

}
