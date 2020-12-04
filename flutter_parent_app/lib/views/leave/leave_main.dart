import 'dart:convert';
import 'dart:io';

import 'package:click_campus_parent/utils/s3_upload.dart';
import 'package:click_campus_parent/views/messages/audio_player_dialog.dart';
import 'package:click_campus_parent/views/messages/msg_video_player.dart';
import 'package:click_campus_parent/views/photo_gallery/photo_gallery_main.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:click_campus_parent/views/teachers/image_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime_type/mime_type.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/g_constants.dart';
import '../../data/app_data.dart';

class LeaveMain extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LeaveState();
  }
}

class LeaveState extends State<LeaveMain> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool _didGetData = false;
  List<dynamic> _leavesData = [];

  List<Map<String, String>> contentData = [
    {"reason": "Reason"},
    {"from_date": "From Date"},
    {"to_date": "To Date"},
    {"applied_timestamp": "Date Applied"},
    {"leave_status": "Status"},
    {"attachment_path": "Attachment"},
  ];

  void _getLeave() async {
    showProgressDialog();
    int userStucareId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var modulesResponse = await http.post(GConstants.getLeaveRoute(), body: {
      "stucare_id": userStucareId.toString(),
      "session_id": activeSession.sessionId.toString(),
      'active_session': sessionToken,
    });

    //print(modulesResponse.body);

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
          _leavesData = modulesResponseObject['data'];
          hideProgressDialog();
          setState(() {});
          return null;
        } else {
          hideProgressDialog();
          showSnackBar(modulesResponseObject["message"]);
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

  void _deleteLeave(String leaveId, int leavePosition) async {
    showProgressDialog();
    String sessionToken = await AppData().getSessionToken();

    var modulesResponse = await http
        .post(GConstants.getDeleteLeaveRoute(), body: {"leave_id": leaveId,
      'active_session': sessionToken,});

    //print(modulesResponse.body);

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
          hideProgressDialog();
          setState(() {
            _leavesData.removeAt(leavePosition);
          });
          showSnackBar("Leave has been deleted", color: Colors.green);
          return null;
        } else {
          hideProgressDialog();
          showSnackBar(modulesResponseObject["message"]);
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

  _launchURL(String theUrl) async {
    if (await canLaunch(theUrl)) {
      await launch(theUrl);
    } else {
      throw 'Cannot open browser for this $theUrl';
    }
  }

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!_didGetData) {
      _didGetData = true;
      Future.delayed(Duration(milliseconds: 1000), () async {
        _getLeave();
      });
    }

    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text("Leave Applications"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (b) => ApplyLeaveDialog(null)))
              .then((b) {
            if (b) {
              showSnackBar("Leave added successfully", color: Colors.green);
              _getLeave();
            }
          });
        },
        child: Text(
          "Apply",
          style: TextStyle(fontSize: 12),
        ),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(8),
        separatorBuilder: (context, position) {
          return Container(
            height: 8,
          );
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if (_leavesData[index]["attachment_path"] != null &&
                  _leavesData[index]["attachment_path"]
                      .toString()
                      .trim()
                      .length >
                      0) {
                switch (_leavesData[index]["attachment_mime"]) {
                  case "image":
                    var photo =
                    Photo(assetName: _leavesData[index]["attachment_path"]);
                    Navigator.push(context, MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return Scaffold(
                            body: SizedBox.expand(
                              child: Hero(
                                tag: photo.tag,
                                child: GridPhotoViewer(photo: photo),
                              ),
                            ),
                          );
                        }));
                    break;
                  case "video":
                    Navigator.push(context, MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return VideoDemo(
                              _leavesData[index]["attachment_path"]);
                        }));
                    break;
                  case "audio":
                    showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          AudioPlayerDialog(
                              _leavesData[index]["attachment_path"]),
                    );
                    break;
                  case "pdf":
                    _launchURL(_leavesData[index]["attachment_path"]);
                    break;
                }
              }
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "Leave No. ${_leavesData[index]["id"]}",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (BuildContext context) =>
                          <PopupMenuItem<String>>[
                            PopupMenuItem<String>(
                              child: const Text('Edit'),
                              value: "0",
                            ),
                            PopupMenuItem<String>(
                              child: const Text('Delete'),
                              value: "1",
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: (selectedButton) async {
                            if (selectedButton == "0") {
                              if (_leavesData[index]["leave_status"] ==
                                  "pending") {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (b) =>
                                            ApplyLeaveDialog(
                                                _leavesData[index]))).then((b) {
                                  if (b) {
                                    showSnackBar("Leave added successfully",
                                        color: Colors.green);
                                    _getLeave();
                                  }
                                });
                              } else {
                                showSnackBar("Only pending leave can be edited",
                                    color: Colors.orange);
                              }
                            }
                            if (selectedButton == "1") {
                              if (_leavesData[index]["leave_status"] ==
                                  "pending") {
                                _deleteLeave(
                                    _leavesData[index]["id"].toString(), index);
                              } else {
                                showSnackBar(
                                    "Only pending leave can be deleted",
                                    color: Colors.orange);
                              }
                            }
                          },
                        )
                      ],
                    ),
                    width: double.infinity,
                    color: Colors.grey.shade900,
                  ),
                  contentTable(index)
                ],
              ),
            ),
          );
        },
        itemCount: _leavesData.length,
      ),
    );
  }

  Widget contentTable(index) =>
      Padding(
        padding: EdgeInsets.all(0),
        child: Table(
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
          },
          children: <TableRow>[]
            ..addAll(contentData.map<TableRow>((Map<String, String> d) {
              var theKey = d.keys.toList()[0];
              return _buildItemRow(d[theKey], _leavesData[index][theKey]);
            })),
        ),
      );

  TableRow _buildItemRow(String left, String right) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            left,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            (left == "Attachment")
                ? (right != null && right
                .trim()
                .length > 0)
                ? "Tap To See"
                : "No File"
                : right,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class ApplyLeaveDialog extends StatefulWidget {
  final Map<String, dynamic> editLeaveData;

  ApplyLeaveDialog(this.editLeaveData);

  @override
  State<StatefulWidget> createState() {
    return ApplyLeaveDialogState();
  }
}

class ApplyLeaveDialogState extends State<ApplyLeaveDialog> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var _reasonTextController;

  DateTime initialDateFrom = DateTime.now();
  DateTime initialDateTo = DateTime.now();
  DateTime dateFrom = DateTime.now();
  DateTime dateTo = DateTime.now();

  String _selectedFilesPath;
  List<Map<String, String>> _filePathsToUpload = [];

  Future getImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 40);

    setState(() {
      _selectedFilesPath = image.path;
      //print(_selectedFilesPath);
    });
  }

  void _openFileExplorer() async {
    if (Theme
        .of(context)
        .platform == TargetPlatform.iOS) {
      var dialog = SimpleDialog(
        title: const Text('Please Select Option'),
        children: [
          SimpleDialogOption(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "Select Photo/Video",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
            ),
            onPressed: () {
              Navigator.pop(context, 0);
            },
          ),
          SimpleDialogOption(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "Select Document",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
            ),
            onPressed: () {
              Navigator.pop(context, 1);
            },
          )
        ],
      );
      showDialog(context: context, builder: (BuildContext context) => dialog)
          .then((value) async {
        if (value == 0) {
          var image = await ImagePicker.pickImage(source: ImageSource.gallery);

          setState(() {
            _selectedFilesPath = image.path;
            //print(_selectedFilesPath);
          });
        } else {
          var path = await FilePicker.getFilePath(type: FileType.any);

          if (path != null && isValidFile(path)) {
            setState(() {
              _selectedFilesPath = path;
              //print(_selectedFilesPath);
            });
          } else {
            showSnackBar("Invalid file");
          }
        }
      });
    } else {
      var path = await FilePicker.getFilePath(type: FileType.any);

      if (path != null && isValidFile(path)) {
        setState(() {
          _selectedFilesPath = path;
          //print(_selectedFilesPath);
        });
      } else {
        showSnackBar("Invalid file");
      }
    }
  }

  bool isValidFile(String path) {
    String mimeType = mime(path);

    if (mimeType.contains("image")) {
      return true;
    } else if (mimeType.contains("video")) {
      return true;
    } else if (mimeType.contains("audio")) {
      return true;
    } else if (mimeType.contains("pdf")) {
      return true;
    }

    return false;
  }

  void _addLeave() async {
    showProgressDialog();
    if (_selectedFilesPath != null) {
      var shouldGoAhead =
      (_selectedFilesPath.contains("s3"))
          ? true
          : await _uploadAttachments();
      if (shouldGoAhead) {
        await _addLeaveFinally();
      } else {
        hideProgressDialog();
      }
    } else {
      await _addLeaveFinally();
    }
  }

  Future<bool> _uploadAttachments() async {
    _filePathsToUpload.clear();
    var filePath = _selectedFilesPath;
    String mimeType = mime(filePath);

    String extension;
    int lastDot = filePath.lastIndexOf('.', filePath.length - 1);
    if (lastDot != -1) {
      extension = filePath.substring(lastDot + 1);
    }

    var fileNameNew =
        "${DateTime
        .now()
        .millisecondsSinceEpoch
        .toString()}.$extension";
    String fileDirectory = "StudentsLeaves";

    var rs = await s3Upload(File(_selectedFilesPath), fileDirectory, fileNameNew);
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
    String _awsURL = await AppData().getBucketUrl();
    map['url'] = "$_awsURL/$schoolBucketName/$fileDirectory/$fileNameNew";

    _filePathsToUpload.add(map);

    return true;
  }

  Future<void> _addLeaveFinally() async {
    int userStucareId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var allClassesResponse =
    await http.post(GConstants.getAddLeaveRoute(), body: {
    "leave_id": widget.editLeaveData != null ? widget.editLeaveData["id"]: "",
    'session_id': activeSession.sessionId.toString(),
    'stucare_id': userStucareId.toString(),
    'reason': _reasonTextController.text,
    'from_date': DateFormat().addPattern("yyyy-MM-dd").format(dateFrom),
    'to_date': DateFormat().addPattern("yyyy-MM-dd").format(dateTo),
    'attachment':
    _filePathsToUpload.length > 0 ? _filePathsToUpload[0]['url'] : "",
    'attachment_mime': _filePathsToUpload.length > 0
    ? _filePathsToUpload[0]['media_type']
        : "",
      'active_session': sessionToken,
    });

    //print(allClassesResponse.body);

    if (allClassesResponse.statusCode == 200) {
      Map allClassesObject = json.decode(allClassesResponse.body);
      if (allClassesObject.containsKey("status")) {
        if (allClassesObject["status"] == "success") {
          hideProgressDialog();
          Navigator.pop(context, true);
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

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
    _reasonTextController = widget.editLeaveData != null
        ? TextEditingController(text: widget.editLeaveData["reason"])
        : TextEditingController();
    if(widget.editLeaveData != null){
      _selectedFilesPath = widget.editLeaveData["attachment_path"];
    }

    if (_selectedFilesPath != null) {
      Map<String, String> map = Map();
      map['media_type'] = widget.editLeaveData["attachment_mime"];
      map['url'] = widget.editLeaveData["attachment_path"];
      _filePathsToUpload.add(map);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text("Apply for Leave"),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                color: Colors.indigo,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 4,
                        child: _InputDropdown(
                          labelText: "From",
                          valueText: widget.editLeaveData != null
                              ? DateFormat.yMMMd().format(DateTime.parse(
                              widget.editLeaveData["from_date"]))
                              : DateFormat.yMMMd().format(dateFrom),
                          valueStyle: Theme
                              .of(context)
                              .textTheme
                              .title
                              .apply(color: Colors.white),
                          onPressed: () async {
                            DateTime firstDate =
                            DateTime.now().subtract(Duration(minutes: 10));
                            final DateTime picked = await showDatePicker(
                              context: context,
                              initialDate: dateFrom,
                              firstDate: firstDate,
                              lastDate: DateTime.now().add(Duration(days: 30)),
                            );
                            if (picked != null)
                              setState(() {
                                dateFrom = picked;
                              });
                          },
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        flex: 4,
                        child: _InputDropdown(
                          labelText: "To",
                          valueText: widget.editLeaveData != null
                              ? DateFormat.yMMMd().format(DateTime.parse(
                              widget.editLeaveData["to_date"]))
                              : DateFormat.yMMMd().format(dateTo),
                          valueStyle: Theme
                              .of(context)
                              .textTheme
                              .title
                              .apply(
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            DateTime initalDate =
                            DateTime.now().subtract(Duration(minutes: 10));
                            final DateTime picked = await showDatePicker(
                              context: context,
                              initialDate: dateTo,
                              firstDate: initalDate,
                              lastDate: DateTime.now().add(Duration(days: 30)),
                            );
                            if (picked != null)
                              setState(() {
                                dateTo = picked;
                              });
                          },
                        ),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                  ),
                ),
              ),
              Form(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 20, 8, 8),
                  child: TextFormField(
                    enabled: true,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter reason for leave"),
                    maxLines: 6,
                    maxLength: 200,
                    validator: (txt) {
                      if (txt.length <= 0) {
                        return "Please enter reason";
                      }
                      return null;
                    },
                    controller: _reasonTextController,
                  ),
                ),
                key: _formKey,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: ButtonTheme(
                  minWidth: 44.0,
                  height: 35,
                  padding: new EdgeInsets.all(6),
                  child: new ButtonBar(children: <Widget>[
                    _selectedFilesPath != null
                        ? Container(
                      child: Text(
                        "Attached file",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    )
                        : Container(
                      height: 0,
                    ),
                    Container(
                      color: Colors.grey.shade400,
                      child: IconButton(
                        icon: Icon(Icons.add_a_photo),
                        iconSize: 18,
                        onPressed: () {
                          getImage();
                        },
                      ),
                      height: 35,
                    ),
                    Container(
                      color: Colors.grey.shade400,
                      child: IconButton(
                        icon: Icon(Icons.attach_file),
                        iconSize: 18,
                        onPressed: () {
                          _openFileExplorer();
                        },
                      ),
                      height: 35,
                    ),
                    new FlatButton(
                      child: new Text(
                        "SUBMIT",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      disabledColor: Colors.indigo,
                      color: Colors.indigo,
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _addLeave();
                        }
                      },
                    ),
                  ]),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _InputDropdown extends StatelessWidget {
  const _InputDropdown({Key key,
    this.child,
    this.labelText,
    this.valueText,
    this.valueStyle,
    this.onPressed})
      : super(key: key);

  final String labelText;
  final String valueText;
  final TextStyle valueStyle;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.white),
          enabledBorder: new UnderlineInputBorder(
              borderSide: new BorderSide(color: Colors.white)),
        ),
        baseStyle: valueStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(valueText, style: valueStyle),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
