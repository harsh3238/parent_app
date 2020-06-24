import 'package:click_campus_parent/views/photo_gallery/photo_gallery_main.dart';
import 'package:click_campus_parent/views/teachers/image_viewer.dart';
import 'package:flutter/material.dart';

class TeachersMain extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return TeachersMainState();
  }
}

class ModelTeacher {
  String teacherName;
  String teacherId;

  ModelTeacher(this.teacherName);
}

class TeachersMainState extends State<TeachersMain> {
  List<ModelTeacher> data = [
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay"),
    ModelTeacher("Ajay")
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Teachers"),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
        children: data.map((ModelTeacher modelTeacher) {
          return getGridItem();
        }).toList(),
      ),
    );
  }

  Widget getGridItem() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute<void>(builder: (BuildContext context) {
          Photo photo = Photo(
              assetName: 'assets/main_back.jpg',
              title: "okay",
              caption: "okay");
          return Scaffold(
            body: SizedBox.expand(
              child: GridPhotoViewer(photo: photo),
            ),
          );
        }));
      },
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: NetworkImage(
                  "http://suditimainpuri.stucareclick.com/Uploads/student_profile/2239.jpg"),
              foregroundColor: Colors.black,
              radius: 40.0,
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Ajay Saxena",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            )
          ],
        ),
      ),
    );
  }
}
