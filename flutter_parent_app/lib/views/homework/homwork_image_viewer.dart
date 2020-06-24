import 'dart:io';

import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final File imageFile;

  FullScreenImage(this.imageFile);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: Image.file(imageFile)),
        SizedBox(
          width: double.infinity,
          child: FlatButton(
              onPressed: (){
                Navigator.pop(context, true);
              },
              child: Text(
                "Upload & Submit",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  side: BorderSide(color: Colors.white))),
        )
      ],
    );
  }
}
