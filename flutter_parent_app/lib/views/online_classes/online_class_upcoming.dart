import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class OnlineClassUpcoming extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return OnlineClassTodaysState();
  }
}

class OnlineClassTodaysState extends State<OnlineClassUpcoming> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _didGetData = false;
  List<dynamic> _liveClassesData = [];

  void _getData() async {
    showProgressDialog();
    String sessionToken = await AppData().getSessionToken();
    int sId = await GConstants.schoolId();
    int userStucareId = await AppData().getSelectedStudent();

    var modulesResponse =
        await http.post(GConstants.getLiveClassesRoute(), body: {
      'active_session': sessionToken,
      'stucare_id': userStucareId.toString(),
      'school_id': sId.toString(),
      'upcoming': "1"
    });

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
          _liveClassesData = modulesResponseObject['data'];
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

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldKey, state: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!_didGetData) {
      _didGetData = true;
      Future.delayed(Duration(milliseconds: 100), () async {
        _getData();
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      body: ListView.builder(
        itemCount: _liveClassesData.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.all(4),
            child: Card(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image(
                        image: AssetImage(
                            getSubjectIcon(_liveClassesData[index]['subject'])),
                        height: 70,
                        width: 150,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                _liveClassesData[index]['topic'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  Text(
                                      "ID : ${_liveClassesData[index]['live_link']}"),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                          text: _liveClassesData[index]
                                              ['live_link']));
                                      showSnackBar("Class ID copied");
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.content_copy, size: 18),
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                      "Pwd : ${_liveClassesData[index]['live_password']}"),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                          text: _liveClassesData[index]
                                          ['live_password']));
                                      showSnackBar("Password copied");
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.content_copy, size: 18),
                                    ),
                                  ),
                                  /*Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                        width: 70,
                                        height: 26,
                                        child: RaisedButton(
                                          child: Text(
                                            "Go to Class",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white),
                                          ),
                                          padding: EdgeInsets.all(0),
                                          onPressed: () {},
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                  )*/
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  Divider(
                    height: 4,
                  ),
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                  "${_liveClassesData[index]['subject']} | ${DateFormat().addPattern("dd-MMM").format(DateTime.parse(_liveClassesData[index]['date_of_class'])).toString()} | ${DateFormat().addPattern("hh:mm a").format(DateTime.parse("0000-00-00 ${_liveClassesData[index]['start_time']}")).toString()} - ${DateFormat().addPattern("hh:mm a").format(DateTime.parse("0000-00-00 ${_liveClassesData[index]['end_time']}")).toString()}",
                                  style: TextStyle(fontSize: 12)),
                              Card(
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Text(
                                    _liveClassesData[index]['subject'] == "0"
                                        ? "Flip"
                                        : "School",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                                color: _liveClassesData[index]['subject'] == "0"
                                    ? Colors.yellow
                                    : Colors.green,
                              )
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.perm_identity,
                                size: 18,
                              ),
                            ),
                            Text("Ashish", style: TextStyle(fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String getSubjectIcon(subName) {
    switch (subName) {
      case "Physics":
        return "assets/class_icons/class_physics.png";
      case "Biology":
        return "assets/class_icons/class_bio.png";
      case "Chemistry":
        return "assets/class_icons/class_chem.png";
      case "Civics":
        return "assets/class_icons/class_civics.png";
      case "Economy":
        return "assets/class_icons/class_eco.png";
      case "English":
        return "assets/class_icons/class_eng.png";
      case "Geology":
        return "assets/class_icons/class_geo.png";
      case "Hindi":
        return "assets/class_icons/class_hindi.png";
      case "History":
        return "assets/class_icons/class_history.png";
      case "Maths":
        return "assets/class_icons/class_maths.png";
      default:
        return "assets/class_icons/class_live.png";
    }
  }
}
