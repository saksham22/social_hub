import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_hub/pages/home.dart';
import 'package:social_hub/widgets/progress.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  bool isUploading = false;
  File file;
  String postId = Uuid().v4();
@override
  void initState() {
    // TODO: implement initState
    super.initState();
    file=null;
    postId = Uuid().v4();
  }
  @override
  Widget build(BuildContext context) {

    return file == null ? buildSplashScreen():buildUpload();
  }

  Widget buildSplashScreen() {
    return Container(
      color:Theme.of(context).accentColor.withOpacity(0.6) ,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/images/upload.svg',height: MediaQuery.of(context).size.height*.8,),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ElevatedButton(
                child: Text("Upload Image"),
                style:ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(100)))
                ),
                onPressed: (){
                  return showDialog(context: context, builder: (c){
                    return SimpleDialog(title: Text("Create Post"),
                    children: [
                      SimpleDialogOption(
                        child: Text("Photo from Camera"),
                        onPressed: handleTakePhoto,

                      ),
                      SimpleDialogOption(
                        child: Text("Image From Gallery"),
                        onPressed: handleGallery,

                      ),
                      SimpleDialogOption(
                        child: Text("Cancel"),
                        onPressed: (){Navigator.pop(c);},

                      ),
                    ],
                    );
                  } );
                },
            ),
          ),
        ],
      ),
    );
  }

  void handleTakePhoto() async {
    Navigator.pop(context);
    File file =await ImagePicker.pickImage(source: ImageSource.camera);
    File cropedFile = await ImageCropper.cropImage(
        sourcePath: file.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
    );
    setState(() {
      this.file = cropedFile;
    });
  }

  void handleGallery() async{
    Navigator.pop(context);
    File file =await ImagePicker.pickImage(source: ImageSource.gallery);
    File cropedFile = await ImageCropper.cropImage(
      sourcePath: file.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],

    );

    setState(() {
      this.file = cropedFile;
    });
  }

  clearImage(){
  setState(() {
    file = null;
  });
  }

  buildUpload() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: (){setState(() {
            file=null;
          });},

        ),
        title:Text("Post"),
        actions: [
          OutlinedButton(
            onPressed: isUploading ?null: ()=> handleSubmit(),
            child:Text(
              "Upload",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),

        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress():Text(""),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width*0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    )
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top:10),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(currentUser.photoUrl),
            ),
            title: Container(
              width: 250,
                child: TextField(
                  controller: captionController,
                  decoration: InputDecoration(
                    hintText: "Write a Caption ... ",
                    border: InputBorder.none
                  ),
                ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35,
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo Taken ?",
                  border: InputBorder.none
                ),
              ),
            ),
          ),
          Container(
            width: 200,
            height: 100,
            alignment: Alignment.center,
            child: ElevatedButton.icon(onPressed: getUserLocation, icon: Icon(Icons.my_location), label: Text("Use my Location")),
          ),
        ],
      ),

    );
  }

  Future<String> uploadImage(imageFile) async{
  StorageUploadTask uploadTask = storageRef.child("post_$postId.jpg").putFile(imageFile);
  StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
  String downloadUrl = await storageSnap.ref.getDownloadURL();
  return downloadUrl;
}

  compressImage() async {
  final tempDir = await getTemporaryDirectory();
  final path = tempDir.path;
  //reading image file
  Im.Image image = Im.decodeImage(file.readAsBytesSync());

  final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(image , quality: 85));
  setState(() {
    file = compressedImageFile;
  });

  }

  handleSubmit() async {
  setState(() {
    isUploading = true;
  });
  await compressImage();
  String mediaUrl = await uploadImage(file);
  createPostInFirestore(
    mediaUrl: mediaUrl,
    location: locationController.text,
    description: captionController.text


  );
  }

   createPostInFirestore({String mediaUrl, String location, String description }) {
    postRef.document(currentUser.id).collection("userPosts").document(postId).setData({
      "postId":postId,
      "ownerId":currentUser.id,
      "username":currentUser.username,
      "mediaUrl":mediaUrl,
      "description":description,
      "location":location,
      "timestamp":DateTime.now(),
      "likes":{},
    });
    captionController.clear();
    locationController.clear();
    setState(() {
      postId = Uuid().v4();
      file=null;
      isUploading = false;
    });

   }

  void getUserLocation() async{
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> pm  = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark p = pm[0];
    // print(p.name);
    // print(p.isoCountryCode);
    // print(p.country);
    // print(p.postalCode);
    // print(p.administrativeArea);
    // print(p.subAdministrativeArea);
    // print(p.locality);
    // print(p.subLocality);
    // print(p.thoroughfare);
    // print(p.subThoroughfare);
    // print(p.position);
    // print(p);
    //
    String formattedAddress = "${p.subLocality}, ${p.locality}, ${p.country}";
    locationController.text=formattedAddress;
  }
}
