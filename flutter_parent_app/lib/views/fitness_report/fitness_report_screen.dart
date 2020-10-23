import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../state_helper.dart';

class FitnessDeclaration extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return FitnessDeclarationState();
  }
}

class FitnessDeclarationState extends State<FitnessDeclaration>
    with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  List<dynamic> _declarationList = [];
  bool _firstRunRoutineRan = false;

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
    if (!_firstRunRoutineRan) {
      Future.delayed(Duration(seconds: 1), () async {
        _getDeclaration();
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text("Today\'s Fitness Declaration"),
      ),
      body: new Container(
        color: Colors.white,
        child: Expanded(
            child: _declarationList.length == 0
                ? Container(
                    alignment: AlignmentDirectional.center,
                    child: new CircularProgressIndicator())
                : ListView.separated(
                    padding: EdgeInsets.all(8),
                    separatorBuilder: (context, position) {
                      return Divider();
                    },
                    itemBuilder: (context, index) {
                      var optionArray = _declarationList[index]["option"];
                      //Map<String, dynamic> map = json.decode(optionArray);
                      //var dateTime = DateTime.parse("${_declarationList[index]['date_of_class']} ${_declarationList[index]['start_time']}");
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                  child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Declaration :",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black38),
                                    ),
                                    Text(
                                        "${_declarationList[index]['declaration']}"),
                                    Row(
                                      children: <Widget>[
                                        Visibility(
                                          child: FlatButton(
                                            onPressed: () {
                                              _saveDeclaration(
                                                  _declarationList[index]
                                                      ['session_id'],
                                                  _declarationList[index]['id'],
                                                  "yes");
                                            },
                                            child: Text(
                                              "Yes",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            color: Colors.indigoAccent,
                                          ),
                                          visible: true,
                                        ),
                                        Visibility(
                                            child: Container(
                                              width: 10,
                                            ),
                                            visible: true),
                                        FlatButton(
                                          onPressed: () {
                                            _saveDeclaration(
                                                _declarationList[index]
                                                    ['session_id'],
                                                _declarationList[index]['id'],
                                                "no");
                                          },
                                          child: Text(
                                            "No",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          color: Colors.indigoAccent,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ))
                            ],
                          ),
                        ),
                      );
                    },
                    itemCount: _declarationList.length,
                  )),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _checkValidation() {
    return true;
  }

  void _saveDeclaration(
      String sessionId, String declarationId, String response) async {
    showProgressDialog();
    String sessionToken = await AppData().getSessionToken();
    int stucareId = await AppData().getUserLoginId();

    var modulesResponse =
        await http.post(GConstants.saveFitnessDeclarationRoute(), body: {
      'declaration_id': declarationId,
      'response': response,
      'stucare_id': stucareId.toString(),
      'session_id': sessionId,
      'active_session': sessionToken,
    });

    //print(modulesResponse.body);

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
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
    } else if (modulesResponse.statusCode == 404) {
      showSnackBar("API Not Found");
    } else {
      showServerError();
    }
    hideProgressDialog();
  }

  void _getDeclaration() async {
    _firstRunRoutineRan = true;
    showProgressDialog();
    String sessionToken = await AppData().getSessionToken();

    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month, now.day);

    final customDateFormat = new DateFormat('yyyy-MM-dd');
    var mDate = customDateFormat.format(date);


    var modulesResponse = await http.post(
        "https://bds.stucarecloud.com/api_v1/student/requests/get_declaration.php",
        body: {
          'class_id': "3",
          'session_id': "3",
          'date_to': mDate,
          'active_session': "b8ebde7e-a069-4b2f-934f-f7f720c55d68",
        });

    debugPrint("${modulesResponse.request} : ${modulesResponse.body}");

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
          hideProgressDialog();
          _declarationList = modulesResponseObject['data'];
          setState(() {});
          return;
        } else {
          hideProgressDialog();
          showSnackBar(modulesResponseObject["message"]);
          return;
        }
      } else {
        showServerError();
      }
    } else if (modulesResponse.statusCode == 404) {
      showSnackBar("API Not Found");
    } else {
      showServerError();
    }
    hideProgressDialog();
  }
}
