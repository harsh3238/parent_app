import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/session_db_provider.dart';
import 'package:click_campus_parent/utils/s3_upload.dart';
import 'package:click_campus_parent/views/login/select_impersonation.dart';
import 'package:click_campus_parent/views/splash/splash_screen.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:click_campus_parent/widgets/profile_tile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime_type/mime_type.dart';

class StudentProfile extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StudentProfileState();
  }
}

class StudentProfileState extends State<StudentProfile> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();

  var deviceSize;
  int currentlyViewedColumn = 0;
  Map<String, dynamic> _profileData;
  Map<String, String> personalInfoData = Map();
  Map<String, String> classInfoData = Map();
  Map<String, String> contactInfoData = Map();
  bool _didGetData = false;
  File _selectedImage = null;
  List<Map<String, String>> _filePathsToUpload = [];
  String profileImageUrl="";
  bool isPictureChangeAllowed = true;
  String imageStatus = "pending";

  void _getProfileData() async {
    showProgressDialog();

    int userStucareId = await AppData().getSelectedStudent();
    var activeSession = await SessionDbProvider().getActiveSession();
    String sessionToken = await AppData().getSessionToken();

    var profileResponse = await http.post(GConstants.getProfileRoute(), body: {
      'stucare_id': userStucareId.toString(),
      'session_id': activeSession.sessionId.toString(),
      'active_session': sessionToken,
    });

    log("${profileResponse.request} : ${profileResponse.body}");
    print("${profileResponse.request} : ${profileResponse.body}");

    if (profileResponse.statusCode == 200) {
      String response = profileResponse.body;
      if(response == "auth error"){
        showSnackBar("Session Expired, Please login again...");
        hideProgressDialog();
        return;
      }
      Map profileResponseObject = json.decode(profileResponse.body);
      if (profileResponseObject.containsKey("status")) {
        if (profileResponseObject["status"] == "success") {
          hideProgressDialog();
          setState(() {
            ///personal Info
            personalInfoData['Father'] =
            profileResponseObject['data']['father_full_name'];
            personalInfoData['Mother'] =
            profileResponseObject['data']['mother_full_name'];
            personalInfoData['Gender'] =
            profileResponseObject['data']['gender'] == "M"
                ? "Male"
                : "Female";
            personalInfoData['Mobile'] =
            profileResponseObject['data']['primary_mobile'];
            personalInfoData['DOB'] = profileResponseObject['data']['dob'];

            ///class info
            classInfoData['Class'] =
            profileResponseObject['data']['class_name'];
            classInfoData['Section'] =
            profileResponseObject['data']['section_name'];
            classInfoData['Session'] =
            profileResponseObject['data']['session_name'];
            classInfoData['S. R. No.'] =
            profileResponseObject['data']['s_r_no'];
            classInfoData['Roll No.'] =
                profileResponseObject['data']['roll_no'] ?? '';

            ///contact info
            contactInfoData['Address'] =
            profileResponseObject['data']['p_address'];
            contactInfoData['City'] = profileResponseObject['data']['p_city'];
            contactInfoData['State'] = profileResponseObject['data']['p_state'];
            contactInfoData['Pin Code'] =
                profileResponseObject['data']['p_postcode'] ?? '';

            _profileData = profileResponseObject['data'];
            imageStatus = _profileData['stu_photo_status'];

            if(_profileData['stu_photo_status']=="approved" && _profileData['photo_student']!=null && _profileData['photo_student']!=""){
              isPictureChangeAllowed = false;
            }else if(_profileData['stu_photo_status']=="disapprove"){
              isPictureChangeAllowed = true;
            }else if(_profileData['stu_photo_status']=="pending"){
              isPictureChangeAllowed = false;
            }
            setState(() {});
          });
          return null;
        } else {
          showSnackBar(profileResponseObject["message"]);
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
    }
    hideProgressDialog();
  }

  void _getSiblings() async {
    showProgressDialog();
    int userLoginId = await AppData().getUserLoginId();
    String sessionToken = await AppData().getSessionToken();

    var siblingsResponse =
    await http.post(GConstants.getSiblingsRoute(), body: {
      'login_row_id': userLoginId.toString(),
      'active_session': sessionToken,
    });

    //print(siblingsResponse.body);

    if (siblingsResponse.statusCode == 200) {
      Map siblingsResponseObject = json.decode(siblingsResponse.body);
      if (siblingsResponseObject.containsKey("status")) {
        if (siblingsResponseObject["status"] == "success") {
          hideProgressDialog();
          List<dynamic> studentList = siblingsResponseObject['siblings'];
          if(studentList.length > 1){
            var dialog = SimpleDialog(
              title: const Text('Please Select Student'),
              children: getStudentList(studentList),
            );
            showDialog(
                context: context,
                builder: (BuildContext context) => dialog,
                barrierDismissible: false
            ).then((value){
              //print("SELECTED stucare ID = $value");
              AppData().setSelectedStudent(int.parse(value[0]));
              AppData().setSelectedStudentName(value[1]);
              _getProfileData();
            });
          }else if (studentList.length == 1){
            showSnackBar("The Student doesn't have any sibling", color: Colors.orange);
          }
          return null;
        } else {
          showSnackBar(siblingsResponseObject["message"]);
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
    }
    hideProgressDialog();
  }

  List<Widget> getStudentList(List<dynamic> students) {
    List<Widget> widgets = List();
    for (Map<String, dynamic> aStudent in students) {
      widgets.add(SimpleDialogOption(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            aStudent['stu_fname'],
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
        onPressed: () {
          Navigator.pop(
              context, [aStudent['stucare_id'], aStudent['stu_fname']]);
        },
      ));
    }
    return widgets;
  }

  void _logUserOut() async {
    showProgressDialog();
    Future.delayed(Duration(milliseconds: 1500), () async {
      await AppData().deleteAllUsers();
      await StateSelectImpersonation.saveImpersonationStatus(null, null);
      hideProgressDialog();
      //Navigator.pop(context);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (BuildContext context) {
            return Scaffold(
              body: SplashScreen(),
            );
          }));
    });
  }

  //Column1
  Widget profileColumn() => Container(
    height: deviceSize.height * 0.24,
    child: FittedBox(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Stack(fit: StackFit.loose, children: <Widget>[
              new Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                      new BorderRadius.all(new Radius.circular(60.0)),
                      border: new Border.all(
                        color: Colors.white,
                        width: 2.0,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage: _profileData != null
                          ? (_profileData['photo_student'] != null &&
                          _profileData['photo_student'] != ""
                          ? NetworkImage(_profileData['photo_student'])
                          : AssetImage("assets/profile.png"))
                          : AssetImage("assets/profile.png"),
                      foregroundColor: Colors.black,
                      radius: 60.0,
                    ),
                  ),
                ],
              ),
              Padding(
                  padding: EdgeInsets.only(top: 70.0, right: 100.0),
                  child: InkWell(
                    onTap: () {
                      if(isPictureChangeAllowed){
                        _pickImage(context);
                      }else{
                       StateHelper().showShortToast(context, "Operation not allowed, Please contact school");
                      }

                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new CircleAvatar(
                          backgroundColor: Colors.indigo,
                          radius: 15.0,
                          child: new Icon(
                            isPictureChangeAllowed? Icons.camera_alt: Icons.lock_outline,
                            color: Colors.white,
                          ),
                        )
                      ],
                    ),
                  )),
            ]),
            ProfileTile(
              title:
              _profileData != null ? _profileData['stu_full_name'] : '',
              subtitle: _profileData != null
                  ? "S. R. No. : ${_profileData['s_r_no']}"
                  : '',
            ),
          ],
        ),
      ),
    ),
  );

  void _pickImage(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                  title: new Text(
                    'Choose Image',
                    style: TextStyle(
                        fontSize: 20,
                        color: const Color(0xff7c7c74),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins'),
                  ),
                ),
                new ListTile(
                    leading: new Icon(Icons.camera_alt),
                    title: new Text('Camera'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _getFromCamera();
                    }),
                new ListTile(
                  leading: new Icon(Icons.photo_album),
                  title: new Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _getFromGallery();
                  },
                ),
              ],
            ),
          );
        });
  }

  _getFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(
        source: ImageSource.camera
    );

    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
    _cropImage(pickedFile.path);
  }
  _getFromGallery() async {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    setState(() {
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
    _cropImage(pickedFile.path);
  }

  _cropImage(filePath) async {
    debugPrint("PATH:" + filePath);
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        cropStyle: CropStyle.rectangle,
        maxWidth: 720,
        maxHeight: 720,
        aspectRatioPresets: [CropAspectRatioPreset.square]);
    if (croppedImage != null) {
      _selectedImage = croppedImage;

      showProgressDialog();
      bool shouldGoAhead = await _uploadImage(_selectedImage);
      if(shouldGoAhead){
        StateHelper().showShortToast(context, "Image Upload Successful");
        setState(() {
          isPictureChangeAllowed = false;
        });
        _updateProfileImage();
      }else{
        hideProgressDialog();
      }

    }
  }

  Widget bodyData() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          profileColumn(),
          tabColumn(deviceSize),
          getActiveColumn(),
          Align(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 8, 8),
              child: Column(
                children: <Widget>[
                  Text(
                    "Active Student",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  GestureDetector(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(border: Border.all(width: 0.5)),
                      child: Text(
                        _profileData != null
                            ? _profileData['stu_full_name']
                            : '',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      _getSiblings();
                    },
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
            alignment: Alignment.centerLeft,
          )
        ],
      ),
    );
  }

  Widget _scaffold() => Scaffold(
    key: _scaffoldState,
    body: bodyData(),
    appBar: AppBar(
      title: Text("Profile"),
      actions: <Widget>[
        FlatButton(
          child: Text("Logout"),
          textColor: Colors.white,
          disabledColor: Colors.white,
          onPressed: () {
            _logUserOut();
          },
        )
      ],
    ),
  );

  Widget tabColumn(Size deviceSize) => Padding(
    padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
    child: Container(
      height: deviceSize.height * 0.06,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          FlatButton(
            child: Text("Personal Info"),
            onPressed: () {
              setState(() {
                currentlyViewedColumn = 0;
              });
            },
            color: currentlyViewedColumn == 0
                ? Colors.grey.shade500
                : Colors.transparent,
          ),
          FlatButton(
            child: Text("Class Info"),
            onPressed: () {
              setState(() {
                currentlyViewedColumn = 1;
              });
            },
            color: currentlyViewedColumn == 1
                ? Colors.grey.shade500
                : Colors.transparent,
          ),
          FlatButton(
            child: Text("Contact Info"),
            onPressed: () {
              setState(() {
                currentlyViewedColumn = 2;
              });
            },
            color: currentlyViewedColumn == 2
                ? Colors.grey.shade500
                : Colors.transparent,
          )
        ],
      ),
      color: Colors.grey.shade300,
    ),
  );

  Widget personalInfoColumn() => Container(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        FlatButton(
          child: Text("Personal Info"),
          onPressed: () {},
        ),
        FlatButton(
          child: Text("Class Info"),
          onPressed: () {},
        ),
        FlatButton(
          child: Text("Contact Info"),
          onPressed: () {},
        )
      ],
    ),
  );

  Widget theInfoTable() => Padding(
    padding: EdgeInsets.all(20),
    child: Table(
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
      },
      children: <TableRow>[]
        ..addAll(personalInfoData.keys.map<TableRow>((keyName) {
          return _buildItemRow(keyName, personalInfoData[keyName]);
        })),
      border: TableBorder.all(color: Colors.grey.shade300),
    ),
  );

  Widget theClassInfoTable() => Padding(
    padding: EdgeInsets.all(20),
    child: Table(
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
      },
      children: <TableRow>[]
        ..addAll(classInfoData.keys.map<TableRow>((keyName) {
          return _buildItemRow(keyName, classInfoData[keyName]);
        })),
      border: TableBorder.all(color: Colors.grey.shade300),
    ),
  );

  Widget theContactInfoTable() => Padding(
    padding: EdgeInsets.all(20),
    child: Table(
      columnWidths: const <int, TableColumnWidth>{
        0: IntrinsicColumnWidth(),
      },
      children: <TableRow>[]
        ..addAll(contactInfoData.keys.map<TableRow>((keyName) {
          return _buildItemRow(keyName, contactInfoData[keyName]);
        })),
      border: TableBorder.all(color: Colors.grey.shade300),
    ),
  );

  TableRow _buildItemRow(String left, String right) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            left,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            right != null ? right : '',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Future<bool> _uploadImage(File image) async {
    String filePath = image.path;
    String mimeType = mime(filePath);

    String extension;
    int lastDot = filePath.lastIndexOf('.', filePath.length - 1);
    if (lastDot != -1) {
      extension = filePath.substring(lastDot + 1);
    }

    var fileNameNew =
        "${DateTime.now().millisecondsSinceEpoch.toString()}.$extension";

    String fileDirectory = "ProfileImages";

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
    String _awsURL = await AppData().getBucketUrl();
    map['url'] = "$_awsURL/$schoolBucketName/$fileDirectory/$fileNameNew";

    _filePathsToUpload.add(map);
    _profileData['photo_student']= "$_awsURL/$schoolBucketName/$fileDirectory/$fileNameNew";
    return true;
  }


  Future<void> _updateProfileImage() async {
    var stucareId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var allClassesResponse =
    await http.post(GConstants.getUpdateProfileImageRoute(), body: {
      'session_id': activeSession.sessionId.toString(),
      'active_session': sessionToken,
      'stucare_id': stucareId.toString(),
      'image': _profileData['photo_student'],
      'status': 'pending',
    });

    print(allClassesResponse.body);

    if (allClassesResponse.statusCode == 200) {
      Map allClassesObject = json.decode(allClassesResponse.body);
      if (allClassesObject.containsKey("status")) {
        if (allClassesObject["status"] == "success") {
          _filePathsToUpload.clear();
          hideProgressDialog();
          showUpdateSuccessDialog();
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

  void showUpdateSuccessDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Images Updated"),
            content: Text("Profile image submitted successfully, New profile image will be visible once approved by school"),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Close"),
              )
            ],
          );
        });

  }


  Widget getActiveColumn() {
    switch (currentlyViewedColumn) {
      case 1:
        return theClassInfoTable();
      case 2:
        return theContactInfoTable();
      default:
        return theInfoTable();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_didGetData) {
      Future.delayed(Duration(milliseconds: 100), () async {
        activeSession = await SessionDbProvider().getActiveSession();
        _getProfileData();
      });
      _didGetData = true;
    }
    deviceSize = MediaQuery.of(context).size;
    return _scaffold();
  }

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState);
  }
}
