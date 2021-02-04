import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/session_db_provider.dart';
import 'package:click_campus_parent/views/polls/poll_preview.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../state_helper.dart';

class StudentPollsMain extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateStudentPollsMain();
  }
}

class StateStudentPollsMain extends State<StudentPollsMain> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool didWeGetData = false;
  List<dynamic> pollList = [];

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!didWeGetData) {
      didWeGetData = true;
      Future.delayed(Duration(milliseconds: 200), () async {
        activeSession = await SessionDbProvider().getActiveSession();
        _getPolls();
      });
    }
    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text("Polls"),
      ),
      body: pollList.length > 0
          ? ListView.separated(
              itemCount: pollList.length,
              itemBuilder: (BuildContext context, int index) {
                Map creator = pollList[index]['creator'];
                DateTime date = DateTime.parse(pollList[index]['created_at']);
                String mDate =
                    DateFormat().addPattern("yyyy-MM-dd h:mm:a").format(date);

                return Container(
                  width: double.maxFinite,
                  child: ListTile(
                    title: Text(
                      pollList[index]['poll_question'],
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    subtitle: SizedBox(
                      width: double.infinity,
                      height: 20,
                      child: RichText(
                          text: TextSpan(
                              style:
                                  TextStyle(color: Colors.black, fontSize: 12),
                              children: [
                            TextSpan(
                              text: "Added By : ",
                            ),
                            TextSpan(
                              text: creator['name'],
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            TextSpan(text: "  |  Date : "),
                            TextSpan(
                              text: mDate,
                              style: TextStyle(color: Colors.grey.shade600),
                            )
                          ])),
                    ),
                    trailing: pollList[index]['poll_question_image'] != null
                        ? SizedBox(
                            width: 50,
                            height: 50,
                            child: CachedNetworkImage(
                              placeholder: (context, url) => Container(
                                child: Image(
                                  image: AssetImage(
                                      "assets/dash_icons/ic_poll_p.png"),
                                  width: 50,
                                  height: 50,
                                  color: Colors.black45,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              imageUrl: pollList[index]['poll_question_image'],
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: 50,
                            height: 50,
                            child: Image(
                              image:
                                  AssetImage("assets/dash_icons/ic_poll_p.png"),
                              width: 50,
                              height: 50,
                              color: Colors.black45,
                              fit: BoxFit.contain,
                            ),
                          ),
                    onTap: () {
                      navigateToModule(PollPreview(pollList[index]));
                    },
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider(
                  height: 4,
                );
              },
            )
          : Center(child: Text("No Data Available")),
    );
  }

  Future<void> _getPolls() async {
    showProgressDialog();
    String sessionToken = await AppData().getSessionToken();
    var stucareId = await AppData().getSelectedStudent();
    if (activeSession == null) {
      StateHelper().showShortToast(
          context, "Please select active session and try again...");
      hideProgressDialog();
      return;
    }

    Map requestBody = {
      'stucare_id': stucareId.toString(),
      'session_id': activeSession.sessionId.toString(),
      'active_session': sessionToken,
    };

    debugPrint("${requestBody}");

    var apiResponse =
        await http.post(GConstants.getPollQuestionsRoute(), body: requestBody);

    debugPrint("${apiResponse.request}:${apiResponse.body}");

    if (apiResponse.statusCode == 200) {
      Map allClassesObject = json.decode(apiResponse.body);
      if (allClassesObject.containsKey("success")) {
        if (allClassesObject["success"] == true) {
          pollList = allClassesObject["data"];
          if (pollList != null && pollList.length == 0) {
            showSnackBar("No Poll Available", color: Colors.indigo);
          }
          setState(() {});
          hideProgressDialog();
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

  void navigateToModule(Widget module) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        body: module,
      );
    })).then((v) {
      if (v) {
        _getPolls();
      }
    });
  }
}
