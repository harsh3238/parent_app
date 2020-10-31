import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
                      var userResponse = _declarationList[index]["user_response"];
                      //Map<String, dynamic> map = json.decode(optionArray);
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
                                    Container(
                                      height: 5,
                                    ),
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

                                              if(userResponse["is_fill"] == true){
                                                showSnackBar("Already responded \"${userResponse["response"]}\" to this question");
                                              }else{
                                                _saveDeclaration(
                                                    _declarationList[index]
                                                    ['session_id'], _declarationList[index]['id'],
                                                    optionArray["0"]);
                                              }
                                            },
                                            child: Text(
                                              optionArray["0"],
                                              style: TextStyle(
                                                  color: Colors.white, ),
                                            ),
                                            color: userResponse["is_fill"] == true?Colors.indigo.withOpacity(0.6):
                                            Colors.indigo,
                                          ),
                                          visible: true,
                                        ),
                                        Container(
                                          width: 10,
                                        ),
                                        FlatButton(
                                          onPressed: () {
                                            if(userResponse["is_fill"] == true){
                                              showSnackBar("Already responded \"${userResponse["response"]}\" to this question");
                                            }else{
                                              _saveDeclaration(
                                                  _declarationList[index]['session_id'],
                                                  _declarationList[index]['id'],
                                                  optionArray["1"]);
                                            }

                                          },
                                          child: Text(
                                            optionArray["1"],
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          color: userResponse["is_fill"] == true?Colors.indigo.withOpacity(0.6):
                                          Colors.indigo,
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

  void _saveDeclaration(int sessionId, int declarationId, String response) async {
    showProgressDialog();

    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month, now.day);

    final customDateFormat = new DateFormat('yyyy-MM-dd');
    var todayDate = customDateFormat.format(date);

    String sessionToken = await AppData().getSessionToken();
    int stucareId = await AppData().getUserLoginId();

    var modulesResponse =
    await http.post(GConstants.saveFitnessDeclarationRoute(), body: {
      'declaration_id': declarationId.toString(),
      'response': response,
      'stucare_id': stucareId.toString(),
      'session_id': sessionId.toString(),
      'date': todayDate,
      'active_session': sessionToken,
    });

    debugPrint("${modulesResponse.request} : ${modulesResponse.body}");

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("success")) {
        if (modulesResponseObject["success"] == true) {
          hideProgressDialog();
          showSnackBar("Response Saved", color: Colors.indigo);
          _getDeclaration();
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
    String sessionToken = await AppData().getSessionToken();

    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month, now.day);

    final customDateFormat = new DateFormat('yyyy-MM-dd');
    var mDate = customDateFormat.format(date);


    var modulesResponse = await http.post(
        GConstants.getFitnessDeclarationRoute(),
        body: {
          'session_id': "3",
          'date': mDate,
          'active_session': sessionToken,
        });

    debugPrint("${modulesResponse.request} : ${modulesResponse.body}");

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("success")) {
        if (modulesResponseObject["success"] == true) {
          _declarationList = modulesResponseObject['data'];
          setState(() {});
          return;
        } else {
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
  }
}
