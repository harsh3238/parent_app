import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/models/model_homework.dart';
import 'package:click_campus_parent/data/session_db_provider.dart';
import 'package:click_campus_parent/views/homework/homework_details.dart';
import 'package:click_campus_parent/views/homework/homework_submissions.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar/flutter_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Homework extends StatefulWidget {
  final int _unseenHomework;

  Homework(this._unseenHomework);

  @override
  State<StatefulWidget> createState() {
    return HomeworkState();
  }
}

class HomeworkState extends State<Homework> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool didGetData = false;
  List<ModelHomework> homeworkList = List();
  Set<int> seenHomework = Set();

  List<Color> items = [
    Colors.red.shade700,
    Colors.blue.shade900,
    Colors.yellow.shade900,
    Colors.pink.shade700,
    Colors.lightBlue.shade700,
    Colors.green.shade700,
    Colors.deepOrange.shade700,
    Colors.lightGreen.shade700,
    Colors.teal.shade700,
    Colors.pink.shade700,
    Colors.purple.shade700,
    Colors.teal.shade900
  ];

  Future<void> _getHomeworkData({String date}) async {
    showProgressDialog();
    int stucareId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var homeworkResponse =
        await http.post(GConstants.getHomeworkRoute(), body: {
      'stucare_id': stucareId.toString(),
      'session_id': activeSession.sessionId.toString(),
      'date': (date != null) ? date : '',
      'active_session': sessionToken,
    });

    //print(homeworkResponse.body);

    if (homeworkResponse.statusCode == 200) {
      Map homeworkResponseObject = json.decode(homeworkResponse.body);
      if (homeworkResponseObject.containsKey("status")) {
        if (homeworkResponseObject["status"] == "success") {
          List<dynamic> data = homeworkResponseObject['data'];
          homeworkList.clear();
          data.forEach((i) {
            homeworkList.add(ModelHomework.fromJson(i));
          });
          try {
            if (homeworkList.length > 0) {
              var y = DateFormat()
                  .addPattern("yyyy-MM-dd")
                  .format(DateTime.now().subtract(Duration(days: 1)));
              var t =
                  DateFormat().addPattern("yyyy-MM-dd").format(DateTime.now());

              var todaysSaved = await AppData().getHomeworkSeen("todays");
              var yesSaved = await AppData().getHomeworkSeen("yesterday");
              if (todaysSaved != null) {
                var savedTimeForSeenHomeworkTodays =
                    DateTime.parse(todaysSaved);
                var savedTimeForSeenHomework = DateTime.parse(yesSaved);

                if (savedTimeForSeenHomeworkTodays.isBefore(DateTime.now()) ||
                    savedTimeForSeenHomework.isBefore(DateTime.now())) {
                  if (date == null || date == t || date == y) {
                    AppData().setHomeworkSeen(null);
                  }
                }
              } else {
                AppData().setHomeworkSeen(null);
              }
            }
          } catch (e) {}
          hideProgressDialog();
          setState(() {});
          return null;
        } else {
          hideProgressDialog();
          showSnackBar(homeworkResponseObject["message"]);
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
    if (!didGetData) {
      didGetData = true;
      Future.delayed(Duration(milliseconds: 500), () async {
        _getHomeworkData();
      });
    }
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Homework"),
        actions: <Widget>[
          FlatButton(
            child: Text(activeSession != null ? activeSession.sessionName : ""),
            textColor: Colors.white,
            disabledColor: Colors.white,
            onPressed: () {
              var dialog = SimpleDialog(
                title: const Text('Change Session'),
                children: allSessions.map((oneSessionItem) {
                  return SimpleDialogOption(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        oneSessionItem.sessionName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700),
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
              ).then((value) async {
                await SessionDbProvider().setActiveSession(value.sessionId);
                activeSession = await SessionDbProvider().getActiveSession();
                didGetData = false;
                _getHomeworkData();
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: WillPopScope(
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Expanded(),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: (homeworkList.length > 0)
                  ? bodyList()
                  : SliverToBoxAdapter(
                      child: Container(
                        child: Center(
                          child: Text(
                            "No homework records available.",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        margin: EdgeInsets.all(10),
                        height: 100,
                      ),
                    ),
            ),
          ],
        ),
        onWillPop: () {
          Navigator.pop(context, seenHomework);
          return null;
        },
      ),
    );
  }

  Widget bodyList() => SliverList(
          delegate:
              SliverChildBuilderDelegate((BuildContext context, int index) {
        seenHomework.add(homeworkList[index].id);
        return listItem(index);
      }, childCount: homeworkList.length));

  Widget listItem(int position) {
    int p = position % 10;

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (b) => HomeworkDetails(homeworkList[position])));
      },
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(DateFormat().add_jm().format(
                DateTime.parse(homeworkList[position].timestampCreated))),
          ),
          Expanded(
            child: Card(
              color: items[p],
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      homeworkList[position].assignmentTitle,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    Container(height: 10),
                    Row(
                      children: <Widget>[
                        Text(
                          (homeworkList[position].subjectName != null &&
                                  homeworkList[position]
                                          .subjectName
                                          .trim()
                                          .length >
                                      0)
                              ? homeworkList[position].subjectName
                              : "All Subjects",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        homeworkList[position].submissionsRequired == 1
                            ? SizedBox(
                                child: FlatButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HomeworkSubmission(
                                                  homeworkList[position]),
                                        ));
                                  },
                                  child: Text(
                                    "Submissions",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(4)),
                                      side: BorderSide(color: Colors.white)),
                                  padding: EdgeInsets.all(0),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                height: 20,
                              )
                            : SizedBox(
                                height: 0,
                              ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
