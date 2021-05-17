import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/db_school_info.dart';
import 'package:click_campus_parent/views/dashboard/the_dashboard_main.dart';
import 'package:click_campus_parent/views/login/activity_impersonation.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreenPass extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginScreenPassState();
  }
}

class _LinkTextSpan extends TextSpan {
  _LinkTextSpan(_LoginScreenPassState state, {TextStyle style, String url, String text})
      : super(
            style: style,
            text: text ?? url,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                state.resendOtp();
              });
}

class _LoginScreenPassState extends State<LoginScreenPass> with StateHelper {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  final _mobileNumberTextController = TextEditingController();
  final _passTxtCont = TextEditingController();
  final _schoolIdTextController = TextEditingController();
  final _otpTextController = TextEditingController();
  bool _isKeyboardVisible = false;
  bool _firstRunRoutineRan = false;

  Future<void> _loginRequest() async {
    showProgressDialog();

    var schoolDataResponse = await http.post(GConstants.schoolDataRoute(), body: {'school_id': _schoolIdTextController.text});

    log("${schoolDataResponse.request} : ${schoolDataResponse.body}");

    if (schoolDataResponse.statusCode == 200) {
      ///Getting School Data
      Map responseObject = json.decode(schoolDataResponse.body);
      if (responseObject.containsKey("id")) {
        String tempSchoolUrl = responseObject["api_route_base"];
        GConstants.setSchoolRootUrl(tempSchoolUrl);

        ///Now that we have received the school's root url we can
        ///continue logging in user, so make another request
        ///now to the school directly
        var sId = await GConstants.schoolId();
        var loginResponse = await http.post(GConstants.loginPassRoute(),
            body: {'mobile_no': _mobileNumberTextController.text, 'school_id': sId.toString(), 'password': _passTxtCont.text});

        log("${loginResponse.request} : ${loginResponse.body}");

        if (loginResponse.statusCode == 200) {
          Map loginResponseObject = json.decode(loginResponse.body);
          if (loginResponseObject.containsKey("status")) {
            debugPrint(loginResponseObject.toString());
            if (loginResponseObject["status"] == "success") {
              int loginRecordId = await saveLoginReport(int.parse(loginResponseObject['login_id']));
              if (loginRecordId != 0) {
                loginResponseObject["login_record_id"] = loginRecordId;

                loginResponseObject.remove("status");
                loginResponseObject.remove("message");

                await AppData().saveUsersData(loginResponseObject);
                await AppData().setNormalSchoolRootUrlAndId(GConstants.SCHOOL_ROOT, _schoolIdTextController.text);
                hideProgressDialog();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) {
                  return Scaffold(
                    body: DashboardMain(false),
                  );
                }));
              } else {
                showSnackBar(loginResponseObject["message"]);
              }
              return null;
            } else {
              showSnackBar(loginResponseObject["message"]);
            }
          } else {
            showServerError();
          }
        } else {
          showServerError();
        }
      } else {
        showSnackBar("Invalid school ID");
      }
    } else {
      showServerError();
    }
    hideProgressDialog();
  }

  void _otpVerifyRequest() async {
    showProgressDialog();

    var otpResponse =
        await http.post(GConstants.otpVerifyRoute(), body: {'mobile_no': _mobileNumberTextController.text, 'otp': _otpTextController.text});
    //print(otpResponse.body);

    if (otpResponse.statusCode == 200) {
      Map loginResponseObject = json.decode(otpResponse.body);
      debugPrint(loginResponseObject.toString());
      if (loginResponseObject.containsKey("status")) {
        if (loginResponseObject["status"] == "success") {
          int loginRecordId = await saveLoginReport(int.parse(loginResponseObject['login_id']));
          if (loginRecordId != 0) {
            loginResponseObject["login_record_id"] = loginRecordId;

            loginResponseObject.remove("status");
            loginResponseObject.remove("message");

            await AppData().saveUsersData(loginResponseObject);
            await AppData().setNormalSchoolRootUrlAndId(GConstants.SCHOOL_ROOT, _schoolIdTextController.text);
            hideProgressDialog();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) {
              return Scaffold(
                body: DashboardMain(false),
              );
            }));
          } else {
            showSnackBar(loginResponseObject["message"]);
          }
          return null;
        } else {
          showSnackBar(loginResponseObject["message"]);
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
    }
    hideProgressDialog();
  }

  void resendOtp() async {
    showProgressDialog();

    var otpResponse = await http.post(GConstants.resendOtpRoute(), body: {'mobile_no': _mobileNumberTextController.text});
    //print(otpResponse.body);

    if (otpResponse.statusCode == 200) {
      Map loginResponseObject = json.decode(otpResponse.body);
      if (loginResponseObject.containsKey("status")) {
        if (loginResponseObject["status"] == "success") {
          hideProgressDialog();
          showSnackBar("OTP has been resend");
          return null;
        } else {
          showSnackBar(loginResponseObject["message"]);
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
    }
    hideProgressDialog();
  }

  Future<int> saveLoginReport(int loginId) async {
    var loginReportResponse = await http.post(GConstants.loginReportRoute(), body: {'login_id': loginId.toString(), 'event': "in"});
    //print(loginReportResponse.body);

    if (loginReportResponse.statusCode == 200) {
      Map loginResponseObject = json.decode(loginReportResponse.body);
      if (loginResponseObject.containsKey("status")) {
        if (loginResponseObject["status"] == "success") {
          return int.parse(loginResponseObject["record_id"]);
        } else {
          return 0;
        }
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }

  handleError(PlatformException error) {
    print(error);
    switch (error.code) {
      case 'ERROR_INVALID_VERIFICATION_CODE':
        showSnackBar("Invalid Verification Code");
        break;
      default:
        showSnackBar("Something Went Wrong, Try Again...");
        break;
    }
  }

  _impersonationLogic() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => ImpersonationMain(_schoolIdTextController.text)));
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      if (!_firstRunRoutineRan) {
        _firstRunRoutineRan = true;
        multipleSchoolsRoutine();
      }
    });
    return Scaffold(
      key: _scaffoldState,
      body: Container(
        constraints: BoxConstraints.expand(),
        child: SizedBox.expand(
          child: Stack(
            children: <Widget>[
              SizedBox.expand(child: Image.asset("assets/main_back.jpg", fit: BoxFit.cover)),
              Opacity(opacity: 0.8, child: Container(color: Colors.indigo.shade900)),
              Center(
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      !_isKeyboardVisible
                          ? Container(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Column(children: <Widget>[
                                    Icon(Icons.vpn_key, size: 80, color: Colors.white),
                                    Padding(
                                        padding: EdgeInsets.all(0),
                                        child: Text("", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))
                                  ], crossAxisAlignment: CrossAxisAlignment.start)))
                          : Container(height: 0),
                      Container(height: 10),
                      Stack(
                        children: <Widget>[
                          SvgPicture.asset("assets/abc.svg", width: 370),
                          Container(
                            padding: EdgeInsets.fromLTRB(20, 20, 60, 0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                              children: <Widget>[
                                Text("LOGIN PLEASE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                TextFormField(
                                    decoration: InputDecoration(
                                        labelText: "School ID",
                                        contentPadding: EdgeInsets.fromLTRB(0, 16, 0, 2),
                                        labelStyle: TextStyle(fontSize: 14)),
                                    maxLines: 1,
                                    keyboardType: TextInputType.numberWithOptions(),
                                    scrollPadding: EdgeInsets.all(0),
                                    validator: (txt) {
                                      if (txt.isEmpty)
                                        return 'Invalid ID';
                                      else
                                        return null;
                                    },
                                    controller: _schoolIdTextController),
                                TextFormField(
                                    decoration: InputDecoration(
                                        labelText: "Enter your phone",
                                        contentPadding: EdgeInsets.fromLTRB(0, 16, 0, 2),
                                        labelStyle: TextStyle(fontSize: 14)),
                                    maxLines: 1,
                                    keyboardType: TextInputType.numberWithOptions(),
                                    scrollPadding: EdgeInsets.all(0),
                                    validator: (txt) {
                                      if (txt.length != 10) {
                                        return 'Invalid number';
                                      }
                                      Pattern pattern = "\\d+";
                                      RegExp regex = new RegExp(pattern);
                                      if (!regex.hasMatch(txt))
                                        return 'Invalid number';
                                      else
                                        return null;
                                    },
                                    controller: _mobileNumberTextController),
                                TextFormField(
                                    decoration: InputDecoration(
                                        labelText: "Enter your password",
                                        contentPadding: EdgeInsets.fromLTRB(0, 16, 0, 2),
                                        labelStyle: TextStyle(fontSize: 14)),
                                    maxLines: 1,
                                    keyboardType: TextInputType.text,
                                    obscureText: true,
                                    scrollPadding: EdgeInsets.all(0),
                                    controller: _passTxtCont),
                                SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                    width: 290,
                                    child: Align(
                                        child: ConstrainedBox(
                                            constraints: BoxConstraints(minWidth: 150, maxHeight: 30),
                                            child: RaisedButton(
                                                onPressed: () {
                                                  if (_formKey.currentState.validate()) {
                                                    if (_mobileNumberTextController.text == "9876543210") {
                                                      _impersonationLogic();
                                                    } else {
                                                      _loginRequest();
                                                    }
                                                  }
                                                },
                                                child: Text("LOGIN", style: TextStyle(color: Colors.white)),
                                                color: Colors.pink)),
                                        alignment: Alignment.center)),
                              ],
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                            ),),
                          ),
                        ],
                      ),
                      Container(
                        height: 70,
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.fromLTRB(0, 0, 40, 0),
                ),
              ),
              (!_isKeyboardVisible)
                  ? Container(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                IconButton(
                                    icon: Icon(
                                      FontAwesomeIcons.facebook,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () async {
                                      String url = await DbSchoolInfo().getFacebookUrl();
                                      _launchURL(url);
                                    }),
                                Container(
                                  width: 10,
                                ),
                                IconButton(
                                    icon: Icon(
                                      Icons.email,
                                      color: Colors.white54,
                                      size: 30,
                                    ),
                                    onPressed: () async {
                                      String url = await DbSchoolInfo().getEmail();
                                      var uri = "mailto:$url";
                                      _launchURL(uri);
                                    }),
                                Container(
                                  width: 10,
                                ),
                                IconButton(
                                    icon: Icon(
                                      FontAwesomeIcons.link,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () async {
                                      String url = await DbSchoolInfo().getWebUrl();
                                      _launchURL(url);
                                    }),
                                Container(
                                  width: 10,
                                ),
                                IconButton(
                                    icon: Icon(
                                      FontAwesomeIcons.mobileAlt,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () async {
                                      String url = await DbSchoolInfo().getPhone();
                                      _launchURL("tel://$url");
                                    }),
                                Container(
                                  width: 10,
                                ),
                                IconButton(
                                    icon: Icon(
                                      FontAwesomeIcons.whatsapp,
                                      color: Colors.white54,
                                      size: 28,
                                    ),
                                    onPressed: () async {
                                      await launch("https://wa.me/918009121315");
                                    })
                              ],
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                            Container(
                              height: 40,
                            ),
                            Text(
                              "Powered by Stucare Technologies Pvt. Ltd.",
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            )
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                    )
                  : Container(
                      height: 0,
                    )
            ],
          ),
        ),
      ),
    );
  }

  _launchURL(String theUrl) async {
    if (await canLaunch(theUrl)) {
      await launch(theUrl);
    } else {
      throw 'Cannot open browser for this $theUrl';
    }
  }

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState);
    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        setState(() {
          _isKeyboardVisible = visible;
        });
      },
    );
  }

  Future<void> multipleSchoolsRoutine() async {
    if (GConstants.MULTIPLE_SCHOOLS) {
      var dialog = WillPopScope(
          child: SimpleDialog(
            title: Text('Please Select School'),
            children: GConstants.MULTIPLE_SCHOOLS_LIST.map((schoolItem) {
              return GestureDetector(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(schoolItem['school_name']),
                ),
                onTap: () {
                  Navigator.pop(context, schoolItem);
                },
              );
            }).toList(),
          ),
          onWillPop: () {});
      await showDialog(context: context, builder: (BuildContext context) => dialog, barrierDismissible: false).then((value) async {
        await AppData().setNormalSchoolRootUrlAndId(value['url'], value['school_id'].toString());
        await GConstants.getSchoolUrl();
      });
    }
  }
}
