import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/session_db_provider.dart';
import 'package:click_campus_parent/views/remark/remark_filter.dart';
import 'package:click_campus_parent/views/remark/view_remark.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state_helper.dart';

class StudentRemarkMain extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _StudentRemarkMainState();
  }
}

class _StudentRemarkMainState extends State<StudentRemarkMain>
    with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool _didGetData = false;
  List<dynamic> _remarkData = [];

  List<dynamic> _remarkTypeList = [];
  Map<String, dynamic> _selectedRemarkType;

  void _getRemarks() async {
    showProgressDialog();
    String sessionToken = await AppData().getSessionToken();
    int studentId = await AppData().getSelectedStudent();


    Map requestBody = {
      'active_session': sessionToken,
      'session_id': activeSession.sessionId.toString(),
      'remarkee_id': studentId.toString(),
      'page_number': "0",
      'limit': "100",
    };

    if (_selectedRemarkType != null && _selectedRemarkType["id"] != 0) {
      requestBody.putIfAbsent('remark_type_id', () => _selectedRemarkType["id"].toString());
    }

    var modulesResponse =
        await http.post(GConstants.getStudentRemarksRoute(), body: requestBody);

    debugPrint("${modulesResponse.request} : ${modulesResponse.body}");

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);

      if (modulesResponseObject.containsKey("success")) {
        if (modulesResponseObject["success"] == true) {
          _remarkData = modulesResponseObject['data'];
          if (_remarkData.length == 0) {
            showSnackBar("No Remark Found", color: Colors.indigo);
          }
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

  void _getRemarkType() async {
    String sessionToken = await AppData().getSessionToken();
    var allClassesResponse =
        await http.post(GConstants.getRemarkTypeRoute(), body: {
      'active_session': sessionToken,
    });

    debugPrint("${allClassesResponse.request} : ${allClassesResponse.body}");

    if (allClassesResponse.statusCode == 200) {
      Map allClassesObject = json.decode(allClassesResponse.body);
      if (allClassesObject.containsKey("success")) {
        if (allClassesObject["success"] == true) {
          _remarkTypeList = allClassesObject['data'];
          _remarkTypeList.add({"remark": "All Remarks", "id": 0});
          setState(() {});
          return null;
        } else {
          showSnackBar(allClassesObject["message"]);
          return null;
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
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
      Future.delayed(Duration(milliseconds: 100), () async {
        activeSession = await SessionDbProvider().getActiveSession();
        _getRemarks();
        _getRemarkType();
      });
    }

    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(title: Text("Remark Calendar"), actions: <Widget>[
        FlatButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) =>
                    RemarkFilter(_remarkTypeList, _selectedRemarkType),
              ).then((onValue) {
                if (onValue != null) {
                  _selectedRemarkType = onValue[0];
                  _getRemarks();
                }
              });
            },
            child: Icon(
              Icons.filter_alt_outlined,
              color: Colors.white,
            ))
      ]),
      body: Column(
        children: <Widget>[
          Expanded(
              child: ListView.builder(
            padding: EdgeInsets.all(0),
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  navigateToModule(ViewRemark(
                      _remarkData[index]['student_name'],
                      "${_remarkData[index]['class']} - ${_remarkData[index]['section']}",
                      _remarkData[index]['description'],
                      _remarkData[index]['remark'],
                      _remarkData[index]['visibility'],
                      _remarkData[index]['category'],
                      _remarkData[index]['creator']));
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Card(
                    child: Column(
                      children: <Widget>[
                        Container(
                          color: _remarkData[index]['category'] == 1
                              ? Color(0xff509F54)
                              : Color(0xffBD4530),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 10,
                              ),
                              _remarkData[index]['photo_student']!=null?
                              CachedNetworkImage(
                                width: 40.0,
                                height: 40.0,
                                imageUrl: _remarkData[index]
                                ['photo_student'],
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                placeholder: (context, url) => Container(
                                    width: 40.0,
                                    height: 40.0,
                                    decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: new DecorationImage(
                                        image: new ExactAssetImage(
                                            'assets/profile.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    )),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                              ):
                              Icon(
                                Icons.account_circle,
                                size: 40,
                                color: Colors.white,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Column(
                                children: <Widget>[
                                  Text(
                                      _remarkData[index]['student_name']
                                          .toString(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 16)),
                                  Text(
                                      "${_remarkData[index]['class']} - ${_remarkData[index]['section']}",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ],
                                crossAxisAlignment: CrossAxisAlignment.start,
                              ),
                              Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: IconButton(
                                      icon: Icon(
                                        _remarkData[index]['category'] == 1
                                            ? Icons.thumb_up_outlined
                                            : Icons.thumb_down_outlined,
                                        size: 35,
                                        color:
                                            _remarkData[index]['category'] == 1
                                                ? Colors.indigo
                                                : Colors.indigo,
                                      ),
                                      highlightColor: Colors.grey,
                                      onPressed: () {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 10, top: 10, bottom: 4),
                          child: Container(
                            color: Colors.white12,
                            height: 50,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  flex: 2, // 20%
                                  child: Container(
                                    child: Text(
                                        _remarkData[index]['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          child: Container(
                            height: 1,
                            color: Colors.black12,
                          ),
                        ),
                        Container(
                          color: Colors.white12,
                          height: 40,
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                flex: 2, // 60%
                                child: Container(
                                  child: Text(
                                    "${_remarkData[index]['created_date']} at ${_remarkData[index]['created_time']}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xffCACFCA)),
                                  ),
                                ),
                              ),
                              Spacer(),
                              SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Image.asset('assets/ic_teacher.jpg')),
                              Text(
                                _remarkData[index]['creator'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black38),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    elevation: 4,
                  ),
                ),
              );
            },
            itemCount: _remarkData.length,
          ))
        ],
      ),
    );
  }

  void navigateToModule(Widget module) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => module),
    );
  }
}
