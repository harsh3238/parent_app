import 'dart:convert';
import 'dart:io';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/models/model_homework.dart';
import 'package:click_campus_parent/utils/s3_upload.dart';
import 'package:click_campus_parent/views/photo_gallery/photo_gallery_main.dart';
import 'package:click_campus_parent/views/teachers/image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';

import '../state_helper.dart';
import 'homwork_image_viewer.dart';

class HomeworkSubmission extends StatefulWidget {
  final ModelHomework _homework;

  HomeworkSubmission(this._homework);

  @override
  State<StatefulWidget> createState() {
    return StateHomeworkSubmission();
  }
}

class StateHomeworkSubmission extends State<HomeworkSubmission>
    with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool _firstRunRoutineRan = false;

  List<dynamic> _usersSubmittedData = [];
  List<Map<String, String>> _filePathsToUpload = [];

  Future<void> _getHomeworkSubmissions() async {
    showProgressDialog();

    var studecarId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var homeworkSubmissions =
        await http.post(GConstants.getHomeworkSubmissionsRoute(), body: {
      'homework_id': widget._homework.id.toString(),
      'stucare_id': studecarId.toString(),
          'active_session': sessionToken,
    });

    //print(homeworkSubmissions.body);

    if (homeworkSubmissions.statusCode == 200) {
      Map homeworkSubmissionsObject = json.decode(homeworkSubmissions.body);
      if (homeworkSubmissionsObject.containsKey("status")) {
        if (homeworkSubmissionsObject["status"] == "success") {
          _usersSubmittedData = homeworkSubmissionsObject['data'];
          hideProgressDialog();
          setState(() {});
          return null;
        } else {
          hideProgressDialog();
          showSnackBar(homeworkSubmissionsObject["message"]);
          return null;
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
    }
    hideProgressDialog();
  }

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstRunRoutineRan) {
      _firstRunRoutineRan = true;
      Future.delayed(Duration(milliseconds: 100), () async {
        _getHomeworkSubmissions();
      });
    }

    return Scaffold(
        key: _scaffoldState,
        appBar: AppBar(
          title: Text("Submissions"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                getImage();
              },
              child: Text(
                "Add Submission",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
        body: Container(
          color: Colors.grey.shade200,
          child: ListView.separated(
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(
                  "Submitted Document Page ${index + 1}",
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
                onTap: () {
                  var photo = Photo(
                      assetName: _usersSubmittedData[index]['attachment_path']);
                  Navigator.push(context,
                      MaterialPageRoute<void>(builder: (BuildContext context) {
                    return Scaffold(
                      body: SizedBox.expand(
                        child: Hero(
                          tag: photo.tag,
                          child: GridPhotoViewer(photo: photo),
                        ),
                      ),
                    );
                  }));
                },
              );
            },
            itemCount: _usersSubmittedData.length,
            separatorBuilder: (BuildContext context, int index) {
              return Divider(
                height: 0,
              );
            },
          ),
        ));
  }

  Future getImage() async {
    showProgressDialog();
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 30);
    if (image != null) {
      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) {
                    return FullScreenImage(image);
                  },
                  fullscreenDialog: true))
          .then((v) {
        if (v != null && v) {
          _addSubmissionsRoutine(image);
        } else {
          hideProgressDialog();
        }
      });
    } else {
      hideProgressDialog();
    }
  }

  Future<bool> _uploadAttachments(File image) async {
    String filePath = image.path;
    String mimeType = mime(filePath);

    String extension;
    int lastDot = filePath.lastIndexOf('.', filePath.length - 1);
    if (lastDot != -1) {
      extension = filePath.substring(lastDot + 1);
    }

    var fileNameNew =
        "${DateTime.now().millisecondsSinceEpoch.toString()}.$extension";

    String fileDirectory = "HomeworkSubmissions";

    var rs = await s3Upload(image, fileDirectory, fileNameNew);
    if (!rs) {
      showSnackBar("Could not upload files");
      return false;
    }

    Map<String, String> map = Map();

    if (mimeType.contains("image")) {
      map['media_type'] = "image";
    } else if (mimeType.contains("video")) {
      map['media_type'] = "video";
    } else if (mimeType.contains("audio")) {
      map['media_type'] = "audio";
    } else if (mimeType.contains("pdf")) {
      map['media_type'] = "pdf";
    }

    String schoolBucketName = GConstants.getBucketDirName();
    map['url'] =
        "https://stucarecloud.s3.ap-south-1.amazonaws.com/$schoolBucketName/$fileDirectory/$fileNameNew";
    _filePathsToUpload.add(map);
    return true;
  }

  void _addSubmissionsRoutine(File image) async {
    var shouldGoAhead = await _uploadAttachments(image);
    if (shouldGoAhead) {
      await _addSubmissions();
    } else {
      hideProgressDialog();
    }
  }

  Future<void> _addSubmissions() async {
    var studecarId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var allClassesResponse =
        await http.post(GConstants.getAddHomeworkSubmissionsRoute(), body: {
      'homework_id': widget._homework.id.toString(),
      'stucare_id': studecarId.toString(),
      'attachments': json.encode(_filePathsToUpload),
          'active_session': sessionToken,
    });

    //print(allClassesResponse.body);

    if (allClassesResponse.statusCode == 200) {
      Map allClassesObject = json.decode(allClassesResponse.body);
      if (allClassesObject.containsKey("status")) {
        if (allClassesObject["status"] == "success") {
          _filePathsToUpload.clear();
          hideProgressDialog();
          showSnackBar('Homework submitted successfully', color: Colors.green);
          _getHomeworkSubmissions();
          return null;
        } else {
          hideProgressDialog();
          showSnackBar(allClassesObject["message"]);
          return null;
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
    }
    hideProgressDialog();
  }
}
