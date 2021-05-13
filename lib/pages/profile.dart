import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:social_hub/models/user.dart';
import 'package:social_hub/pages/edit_profile.dart';
import 'package:social_hub/widgets/header.dart';
import 'package:social_hub/widgets/post.dart';
import 'package:social_hub/widgets/post_tile.dart';
import 'package:social_hub/widgets/progress.dart';
import 'home.dart';

class Profile extends StatefulWidget {
   final String profileId;
   Profile({this.profileId});
   @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId= currentUser?.id;
  bool isLoading = false;
  String postOrientation = "grid";
  int postCount = 0;
  List<Post> posts = [];
  bool isFollowing=false;
  int followerCount=0;
  int followingCount=0;
  @override
  void initState() {
    // TODO: implement initState
      super.initState();
      getProfilePosts();
      getFollowers();
      getFollowing();
      checkIfFollowing();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,"Profile"),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(),
          buildTogglePost(),
          Divider(
            height: 0.0,
          ),
          buildProfilePost(),
          // Center(
          //   child: Container(
          //     child: GestureDetector(
          //       onTap: (){googleSignIn.signOut();},
          //       child: Container(
          //         alignment: Alignment.center,
          //         height: MediaQuery.of(context).size.height*.04,
          //         width: MediaQuery.of(context).size.width*.8,
          //         decoration: BoxDecoration(
          //           color: Colors.blue,
          //           borderRadius: BorderRadius.circular(4),
          //
          //         ),
          //         child:Text(
          //           'Logout',
          //           style: TextStyle(
          //             color:Colors.white,
          //           ),
          //
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );

  }

  buildProfileHeader() {
    return FutureBuilder(
        future: userRef.document(widget.profileId).get(),
        builder: (context,snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                      backgroundColor: Colors.grey,
                    ),
                    Expanded(child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildCountColumn("post",postCount),
                            buildCountColumn("followers",followerCount),
                            buildCountColumn("following",followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),flex: 1,)
                  ],
                ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top:12),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top:4),
                  child: Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top:2),
                  child: Text(
                    user.bio,

                  ),
                ),
              ],

            ),
          );
        });
  }

  buildCountColumn(String s, int i) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          i.toString(),
          style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            s,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  buildProfileButton() {
    //if Viewing own profile should show edit
    bool isProfileOwner = currentUserId == widget.profileId;
    if(isProfileOwner){
      return buildButton(
        text:"Edit Profile",
        function:editProfile,
      );
    }
    else if(isFollowing){
      return buildButton(text: "Unfollow",function: handleUnfollowUser);
    }
    else if(!isFollowing){
      return buildButton(text: "Follow",function: handlefollowUser);
    }
    // return Text("Edit Profile");
  }

  Container buildButton({String text,  Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2),

      child: TextButton(

        onPressed: function,
        child: Container(
          width: 250,
          height: 27,
          alignment: Alignment.center,
          child: Text(text,style: TextStyle(color: isFollowing ? Colors.black:Colors.white,fontWeight: FontWeight.bold),),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white:Colors.blue,
            border: Border.all(
              color:isFollowing ? Colors.grey: Colors.blue,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  editProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (cont)=>EditProfile(currentUserId:currentUserId)));
    setState(() {
      buildProfileHeader();
    });
  }

  buildProfilePost() {
    if(isLoading){
      return circularProgress();
    }
    else if(posts.isEmpty){
      return Container(
        color:Theme.of(context).accentColor.withOpacity(0.6) ,
        child: Stack(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/no_content.svg',height: MediaQuery.of(context).size.height*.6,),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(
                    "No Posts",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    else if(postOrientation=="grid"){
      List<GridTile> grid=[];
      posts.forEach((post) {
        grid.add(GridTile(child:PostTile(post:post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: grid,
      );
    }
    else if(postOrientation=="column"){
      return Column(children: posts,);
    }

  }

  void getProfilePosts() async{
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snap = await postRef.document(widget.profileId).collection('userPosts').orderBy('timestamp',descending: true).getDocuments();
    setState(() {
      isLoading = false;
      postCount = snap.documents.length;
      posts = snap.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildTogglePost() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(icon: Icon(Icons.grid_on), onPressed:()=>setPostOrientation("grid"),
        color: postOrientation =="grid" ?Theme.of(context).primaryColor:Colors.grey),
        IconButton(icon: Icon(Icons.list), onPressed: ()=>setPostOrientation("column"),
            color: postOrientation =="column" ?Theme.of(context).primaryColor:Colors.grey),
      ],
    );
  }
  setPostOrientation(String s){
    setState(() {
      postOrientation=s;
    });
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
      getFollowing();
      getFollowers();
    });
    //make auth user follower of another user (update their followers collection)
    followersRef.document(widget.profileId).collection("userFollowers").document(currentUserId).get().then((doc){if(doc.exists){
    doc.reference.delete();
    }
    });
    followRef.document(currentUserId).collection("userFollowing").document(widget.profileId).get().then((doc){if(doc.exists){
      doc.reference.delete();
    }
    });
    activityFeedRef.document(widget.profileId).collection("feedItems").document(currentUserId).get().then((doc){if(doc.exists){
      doc.reference.delete();
    }
    });
  }

  handlefollowUser() {
    setState(() {
      isFollowing = true;
      getFollowing();
      getFollowers();
    });
    //make auth user follower of another user (update their followers collection)
    followersRef.document(widget.profileId).collection("userFollowers").document(currentUserId).setData({});
    followRef.document(currentUserId).collection("userFollowing").document(widget.profileId).setData({});
    activityFeedRef.document(widget.profileId).collection("feedItems").document(currentUserId).setData({
      "type":"follow",
      "ownerID":widget.profileId,
      "username":currentUser.username,
      "userId":currentUserId,
      "userProfileImg":currentUser.photoUrl,
      "timestamp":DateTime.now(),
    });
  }

  void checkIfFollowing() async{
    DocumentSnapshot doc= await followersRef.document(widget.profileId).collection("userFollowers").document(currentUserId).get();
    setState(() {
      isFollowing=doc.exists;
    });
  }

  void getFollowing() async{
    QuerySnapshot q=await followRef.document(widget.profileId).collection("userFollowing").getDocuments();
    setState(() {
      followingCount=q.documents.length;
    });
  }

  void getFollowers() async{
    QuerySnapshot q=await followersRef.document(widget.profileId).collection("userFollowers").getDocuments();
    setState(() {
      followerCount=q.documents.length;
    });
  }
}
