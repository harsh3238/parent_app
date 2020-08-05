import 'dart:convert';
import 'dart:io';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/models/syllabus.dart';
import 'package:click_campus_parent/data/models/the_session.dart';
import 'package:click_campus_parent/data/session_db_provider.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadsMain extends StatefulWidget {
  @override
  State createState() {
    return DownloadsMainState();
  }
}

class DownloadsMainState extends State<DownloadsMain> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool _firstRunRoutineRan = false;
  bool _isDownloaderRunning = false;

  List<dynamic> _syllabusList = List();

  List<TheSession> _allSessions = List();
  TheSession _activeSession;

  bool downloading = false;
  var progress = "";

  void _getDownloads() async {
    _firstRunRoutineRan = true;
    showProgressDialog();

    int stucareId = await AppData().getSelectedStudent();

    _allSessions = await SessionDbProvider().getAllSessions();
    String sessionToken = await AppData().getSessionToken();

    var allClassesResponse =
        await http.post(GConstants.getDownloadsRoute(), body: {
      'stucare_id': stucareId.toString(),
      'active_session': sessionToken,
    });

    ////print(allClassesResponse.body);

    if (allClassesResponse.statusCode == 200) {
      Map allClassesObject = json.decode(allClassesResponse.body);
      if (allClassesObject.containsKey("status")) {
        _syllabusList.clear();
        if (allClassesObject["status"] == "success") {
          _syllabusList = allClassesObject['data'];
          hideProgressDialog();
          setState(() {});
          return null;
        } else {
          hideProgressDialog();
          setState(() {});
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

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState);
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstRunRoutineRan) {
      Future.delayed(Duration(milliseconds: 100), () async {
        _getDownloads();
      });
    }
    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(title: Text("Downloads"),),
      body: SafeArea(
          child: CustomScrollView(
        slivers: <Widget>[
          SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
            return GestureDetector(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Text(_syllabusList[index]['title'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 12)),
                          Text(
                              "Date : ${DateFormat().addPattern("dd-MM-yyyy 'at' hh:mm a").format(DateTime.parse(_syllabusList[index]['created_timestamp']))}",
                              style: TextStyle(
                                  color: Colors.grey.shade800, fontSize: 12)),
                        ],
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                    ],
                  ),
                ),
                elevation: 0,
              ),
              onTap: () async {
                var f = _syllabusList[index]['media_path'];
                var p = await _findLocalPath();
                var fileName = f.substring(f.lastIndexOf("/") + 1, f.length);
                var file = File(p + fileName);
                if (file.existsSync()) {
                  OpenFile.open(file.path);
                } else {
                  _requestDownload(f, fileName);
                }
              },
            );
          }, childCount: _syllabusList.length))
        ],
      )),
    );
  }

  _launchURL(String theUrl) async {
    if (await canLaunch(theUrl)) {
      await launch(theUrl);
    } else {
      throw 'Cannot open browser for this $theUrl';
    }
  }

  void _requestDownload(String fielurl, fileName) async {
    var b = await _checkPermission();
    if (b) {
      downloadFile(fielurl, fileName);
    }
  }

  Future<String> _findLocalPath() async {
    final directory = await getExternalStorageDirectory();
    final savedDir = Directory(directory.path + '/Download/');
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
    return savedDir.path;
  }

  Future<void> downloadFile(imgUrl, fileName) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    width: 16,
                  ),
                  Text("Downloading..."),
                ],
              ),
            ),
          );
        });

    Dio dio = Dio();
    String dirloc = await _findLocalPath();
    var completePath = dirloc + fileName;
    try {
      await dio.download(imgUrl, completePath,
          onReceiveProgress: (receivedBytes, totalBytes) {
        downloading = true;
        progress =
            ((receivedBytes / totalBytes) * 100).toStringAsFixed(0) + "%";
        //print("DOWNLOADEDING $progress");
      });
    } catch (e) {
      //print(e);
      Navigator.pop(context);
      showSnackBar("Download failed");
      return null;
    }

    //print("DOWNLOADED $completePath");
    downloading = false;
    Navigator.pop(context);
    showSnackBar("Download completed", color: Colors.green);
    OpenFile.open(completePath);
  }

  Future<bool> _checkPermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage);
      if (permission != PermissionStatus.granted) {
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler()
                .requestPermissions([PermissionGroup.storage]);
        if (permissions[PermissionGroup.storage] == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }
}
