import 'package:flutter/material.dart';

header(context , String s, {leed = true}) {
  return AppBar(
    automaticallyImplyLeading: leed,
    title: Text(
      "$s",
      style: TextStyle(
        color: Colors.white,
        fontFamily: "Signatra",
        fontSize: 50
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
