import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/session_db_provider.dart';
import 'package:click_campus_parent/views/login/select_impersonation.dart';
import 'package:click_campus_parent/views/splash/splash_screen.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:click_campus_parent/widgets/profile_tile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileOnePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ProfileOnePageState();
  }
}

class ProfileOnePageState extends State<ProfileOnePage> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();

  var deviceSize;
  int currentlyViewedColumn = 0;
  Map<String, dynamic> _profileData;
  Map<String, String> personalInfoData = Map();
  Map<String, String> classInfoData = Map();
  Map<String, String> contactInfoData = Map();
  bool _didGetData = false;

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

    //print(profileResponse.body);

    if (profileResponse.statusCode == 200) {
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
      Navigator.pop(context);
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
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
                      ? (_profileData['photo_student'] != null
                      ? NetworkImage(_profileData['photo_student'])
                      : AssetImage("assets/profile.png"))
                      : AssetImage("assets/profile.png"),
                  foregroundColor: Colors.black,
                  radius: 60.0,
                ),
              ),
            ),
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

  //column2

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
