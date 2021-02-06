import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state_helper.dart';

class PollPreview extends StatefulWidget {
  Map pollQuestion;

  PollPreview(this.pollQuestion);

  @override
  State createState() => StatePollPreview();
}

class StatePollPreview extends State<PollPreview> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool isAttempted = false;
  bool didWeGetData = false;
  int selectedItemIndex = -1;

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!didWeGetData) {
      didWeGetData = true;
      checkUserAttempt();
    }
    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text("Poll Preview"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Column(
                    children: <Widget>[
                      Align(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            widget.pollQuestion['poll_question'],
                            style: TextStyle(
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        alignment: Alignment.center,
                      ),
                      widget.pollQuestion['poll_question_image'] != null
                          ? Align(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Image.network(
                                  widget.pollQuestion['poll_question_image'],
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              alignment: Alignment.center,
                            )
                          : Container(
                              height: 10,
                            ),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ),
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                  List<dynamic> _optionList = widget.pollQuestion['options'];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: (selectedItemIndex != -1 &&
                                      selectedItemIndex == index)
                                  ? Colors.green
                                  : Colors.white,
                              spreadRadius: 3),
                        ],
                      ),
                      child: ListTile(
                        onTap: () {
                          if (!isAttempted) {
                            selectedItemIndex = index;
                            setState(() {});
                          }
                        },
                        title: Text(
                          _optionList[index]['option'],
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: RichText(
                            text: TextSpan(
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                children: [
                              TextSpan(
                                text: "Option " + (index + 1).toString(),
                              ),
                            ])),
                        trailing: _optionList[index]['option_image'] != ""
                            ? Padding(
                                padding: EdgeInsets.all(4),
                                child: Image.network(
                                  _optionList[index]['option_image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ))
                            : Container(
                                width: 10,
                              ),
                      ),
                    ),
                  );
                }, childCount: widget.pollQuestion['options'].length))
              ],
            ),
          ),
          Visibility(
            visible: !isAttempted,
            child: Align(
              child: Container(
                color: Colors.indigo,
                child: FlatButton(
                    onPressed: () {
                      checkValidation();
                    },
                    child: Text(
                      "Submit Your Poll",
                      style: TextStyle(color: Colors.white),
                    )),
                width: double.infinity,
              ),
              alignment: Alignment.bottomCenter,
            ),
          )
        ],
      ),
    );
  }

  void checkValidation() {
    if (selectedItemIndex != -1) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Submit Poll?"),
              content: Text("Are you sure you want to submit the poll ? "),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel"),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _savePollMessage();
                  },
                  child: Text("Submit"),
                )
              ],
            );
          });
    } else {
      StateHelper().showShortToast(context,
          "Please select answer for this poll by tapping on your choice");
    }
  }

  Future<void> _savePollMessage() async {
    showProgressDialog();
    String sessionToken = await AppData().getSessionToken();
    var stucareId = await AppData().getSelectedStudent();

    List<dynamic> _optionList = widget.pollQuestion['options'];

    Map requestBody = {
      'session_id': activeSession.sessionId.toString(),
      'active_session': sessionToken,
      'stucare_id': stucareId.toString(),
      'question_id': widget.pollQuestion['id'].toString(),
      'option_id': _optionList[selectedItemIndex]['id'].toString()
    };

    debugPrint("${requestBody}");

    var allClassesResponse =
        await http.post(GConstants.getSavePollAnswerRoute(), body: requestBody);

    debugPrint("${allClassesResponse.request}:${allClassesResponse.body}");

    if (allClassesResponse.statusCode == 200) {
      Map allClassesObject = json.decode(allClassesResponse.body);
      if (allClassesObject.containsKey("success")) {
        if (allClassesObject["success"] == true) {
          //showSnackBar('Poll Published Successfully', color: Colors.green);
          StateHelper().showShortToast(context, "Poll Submitted");
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

  void checkUserAttempt() {
    List<dynamic> _optionList = widget.pollQuestion['options'];

    for (int i = 0; i < _optionList.length; i++) {
      List<dynamic> _answerList = _optionList[i]['option_answer'];
      if (_answerList.isNotEmpty) {
        selectedItemIndex = i;
        isAttempted = true;
      }
    }
    setState(() {});
  }
}
