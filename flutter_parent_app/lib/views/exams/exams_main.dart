import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/session_db_provider.dart';
import 'package:click_campus_parent/views/exams/exam_web_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state_helper.dart';

enum ExamResultType { marks_obtained, weightage }

class ExamsMain extends StatefulWidget {
  @override
  State createState() => ExamsMainState();
}

class ExamsMainState extends State<ExamsMain> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool _firstRunRoutineRan = false;

  List<Map<String, dynamic>> _terms = [];
  Map<String, dynamic> _selectedTerm;

  List<Map<String, dynamic>> _exams = [];
  Map<String, dynamic> _selectedExam;

  ExamResultType _examResultType = ExamResultType.marks_obtained;

  void _getTerms() async {
    showProgressDialog();
    _selectedExam = null;
    _selectedTerm = null;
    String sessionToken = await AppData().getSessionToken();

    var allClassesResponse = await http.post(GConstants.getExamTerms(), body: {
      'session_id': activeSession.sessionId.toString(),
      'active_session': sessionToken,
    });

    //print(allClassesResponse.body);

    if (allClassesResponse.statusCode == 200) {
      Map allClassesObject = json.decode(allClassesResponse.body);
      if (allClassesObject.containsKey("status")) {
        if (allClassesObject["status"] == "success") {
          List<dynamic> data = allClassesObject['data'];
          _terms.clear();
          data.forEach((theItem) {
            _terms.add(theItem);
          });
          hideProgressDialog();
          setState(() {});
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

  void _getExams() async {
    showProgressDialog();

    int userStucareId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var allClassesResponse =
        await http.post(GConstants.getScholasticExamsRoute(), body: {
      'session_id': activeSession.sessionId.toString(),
      'term_id': _selectedTerm['id'],
      'stucare_id': userStucareId.toString(),
          'active_session': sessionToken,
    });

    //print(allClassesResponse.body);

    if (allClassesResponse.statusCode == 200) {
      Map allClassesObject = json.decode(allClassesResponse.body);
      if (allClassesObject.containsKey("status")) {
        if (allClassesObject["status"] == "success") {
          List<dynamic> data = allClassesObject['data'];
          _exams.clear();
          _selectedExam = null;
          var map = Map<String, dynamic>();
          map['id'] = -1;
          map['exam_name'] = "All";
          map['sequence'] = 0;
          _exams.add(map);
          data.forEach((theItem) {
            _exams.add(theItem);
          });
          hideProgressDialog();
          setState(() {});
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

  void _getProfileData() async {
    showProgressDialog();

    int userStucareId = await AppData().getSelectedStudent();
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
          var classsId = profileResponseObject['data']['class_id'];
          var sectionId = profileResponseObject['data']['section_id'];

          hideProgressDialog();
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return ExamWebView(
                activeSession.sessionId.toString(),
                _selectedTerm['id'].toString(),
                (_selectedExam['id'] == -1) ? "all" : _selectedExam['id'].toString(),
                classsId,
                sectionId,
                _examResultType == ExamResultType.marks_obtained
                    ? "marks"
                    : "weightage",
                userStucareId.toString());
          }));

          return null;
        } else {
          showSnackBar("Class/Section data not found");
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
      Future.delayed(Duration(milliseconds: 500), () async {
        _getTerms();
      });
    }

    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text("Exams"),
          actions: <Widget>[
            FlatButton(
              child: Text(activeSession != null ? activeSession.sessionName : ""),
              textColor: Colors.white,
              disabledColor: Colors.white,
              onPressed: () {
                var dialog = SimpleDialog(
                  title: const Text('Change Session'),
                  children: allSessions.map((oneSessionItem){
                    return SimpleDialogOption(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          oneSessionItem.sessionName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context, oneSessionItem);
                      },
                    );
                  }).toList(),
                );
                showDialog(
                  context: context,
                  builder: (BuildContext context) => dialog,
                ).then((value) async{
                  await SessionDbProvider().setActiveSession(value.sessionId);
                  activeSession = await SessionDbProvider().getActiveSession();
                  setState(() {
                  });
                  _getTerms();
                });
              },
            ),
          ]
      ),
      body: Column(children: <Widget>[
        Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: DropdownButton<dynamic>(
              items: _terms
                  .map((b) => DropdownMenuItem<dynamic>(
                        child: Text(
                          b['term_name'],
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                        value: b,
                      ))
                  .toList(),
              onChanged: (b) {
                if (b == _selectedTerm) {
                  return;
                }

                setState(() {
                  _selectedTerm = b;
                });
                _getExams();
              },
              hint: Text(
                'Select Term',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              value: _selectedTerm,
              isExpanded: true,
            )),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: DropdownButton<dynamic>(
            items: _exams
                .map((b) => DropdownMenuItem<dynamic>(
                      child: Text(
                        b['exam_name'],
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      value: b,
                    ))
                .toList(),
            onChanged: (b) {
              if (b == _selectedExam) {
                return;
              }

              setState(() {
                _selectedExam = b;
              });
              //_getSubjects(examId: b['id']);
            },
            hint: Text(
              'Select Exam',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            isExpanded: true,
            value: _selectedExam,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: <Widget>[
              Radio<ExamResultType>(
                value: ExamResultType.marks_obtained,
                groupValue: _examResultType,
                onChanged: (ExamResultType value) {
                  setState(() {
                    _examResultType = value;
                  });
                },
              ),
              Text(
                "Marks Obtained",
                style: TextStyle(fontSize: 11),
              ),
              Radio<ExamResultType>(
                value: ExamResultType.weightage,
                groupValue: _examResultType,
                onChanged: (ExamResultType value) {
                  setState(() {
                    _examResultType = value;
                  });
                },
              ),
              Text(
                "Weightage",
                style: TextStyle(fontSize: 11),
              ),
            ],
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
          ),
        ),
        Expanded(
          child: Align(
            child: Container(
              child: RawMaterialButton(
                child: new Text(
                  "PROCEED",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                onPressed: () {
                  if(_selectedTerm == null){
                    showSnackBar("Please select term", color: Colors.orange);
                    return;
                  }
                  if(_selectedExam == null){
                    showSnackBar("Please select exam", color: Colors.orange);
                    return;
                  }
                  _getProfileData();
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              color: Colors.indigo,
              width: double.infinity,
            ),
            alignment: Alignment.bottomCenter,
          ),
        )
      ]),
    );
  }
}
