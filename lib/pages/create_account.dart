import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_hub/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String username;

  submit() {
   final form = _formKey.currentState;
   if(form.validate()){
     form.save();
     SnackBar snackbar = SnackBar(content: Text("Welcome $username!!") );
     _scaffoldKey.currentState.showSnackBar(snackbar);
     Timer(Duration(seconds: 2),(){
       Navigator.pop(context, username);
     });

   }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, "Set up Username",leed: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(

          children: [

            Text("Create a Username"),
            Form(
              autovalidateMode: AutovalidateMode.always,
              key: _formKey,
                child: TextFormField(
              validator: (val){
                if(val.trim().length<5||val.isEmpty){
                  return 'username to short';
                }
                else if (val.trim().length>20){
                  return 'username to big';
                }
                else return null;

              },
              onSaved: (val) => username = val,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Username",
                hintText: "Must be at least 5 characters",
              ),
            ),
            ),
            SizedBox(
              height: 20,
              width: 150,
              child: Divider(

                  color: Colors.teal.shade900
              ),
            ),
            GestureDetector(
              onTap: submit,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.height*0.06,
                child: Center(
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(7),

                ),

              ),

            ),
          ],
        ),
      ),
    );
  }

}
