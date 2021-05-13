import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_hub/models/user.dart';
import 'package:social_hub/pages/profile.dart';
import 'package:social_hub/widgets/progress.dart';
import 'home.dart';
class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  Future<QuerySnapshot> searchResult;
  handleSearch(String Query) async {
    Future<QuerySnapshot> users = userRef.where("username",isGreaterThanOrEqualTo:Query).getDocuments();
    setState(() {
      searchResult = users;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: buildSearchField(),
      body: searchResult == null ? buidNoContent():buildSearchResults(),
    );
  }
  TextEditingController txtCtrl =TextEditingController();
  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: txtCtrl,
        decoration: InputDecoration(
          hintText: "Search for user...",
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: (){
              txtCtrl.clear();
              },

          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  buidNoContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Theme.of(context).accentColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            SvgPicture.asset("assets/images/search.svg",height: MediaQuery.of(context).size.height*.4,),
            Text(
              "Find User",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future:searchResult,
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc){
          User user = User.fromDocument(doc);
          UserResult uR =UserResult(user);
          searchResults.add(uR);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }


}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: [
          GestureDetector(
            onTap: ()=>showProfile(context,profileId: user.id),
            child:ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                backgroundColor: Colors.grey,
              ),
              title: Text(
                user.displayName,
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                  user.username,
                style: TextStyle(color: Colors.white54),
              ),

            )
          ),
          Divider(
            height: 2,
            color: Colors.white,
          )

        ],
      ),
    );
  }
  showProfile(BuildContext context,{String profileId}){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(profileId: profileId,)));
  }

}
