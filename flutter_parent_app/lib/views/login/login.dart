import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/db_school_info.dart';
import 'package:click_campus_parent/views/dashboard/the_dashboard_main.dart';
import 'package:click_campus_parent/views/login/activity_impersonation.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginScreenState();
  }
}

class _LinkTextSpan extends TextSpan {
  _LinkTextSpan(_LoginScreenState state,
      {TextStyle style, String url, String text})
      : super(
            style: style,
            text: text ?? url,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                state.resendOtp();
              });
}

class _LoginScreenState extends State<LoginScreen> with StateHelper {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyOtp = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  final _mobileNumberTextController = TextEditingController();
  final _schoolIdTextController = TextEditingController();
  final _otpTextController = TextEditingController();
  bool _isKeyboardVisible = false;
  bool _showOtpUi = false;
  bool _firstRunRoutineRan = false;

  Timer _timer;
  int _start = 30;
  String _resendOtpLabel;

  Future<void> _loginRequest() async {
    showProgressDialog();

    var schoolDataResponse = await http.post(GConstants.schoolDataRoute(),
        body: {'school_id': _schoolIdTextController.text});

    debugPrint("${schoolDataResponse.request} : ${schoolDataResponse.body}");

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
        var loginResponse = await http.post(GConstants.loginRoute(), body: {
          'mobile_no': _mobileNumberTextController.text,
          'school_id': sId.toString()
        });

        log("${loginResponse.request} : ${loginResponse.body}");

        if (loginResponse.statusCode == 200) {
          Map loginResponseObject = json.decode(loginResponse.body);
          if (loginResponseObject.containsKey("status")) {
            debugPrint(loginResponseObject.toString());
            if (loginResponseObject["status"] == "success") {
              if (loginResponseObject["otp"] == "firebase") {
                _verifyPhoneNumber();
              } else {
                hideProgressDialog();
                setState(() {
                  _showOtpUi = true;
                });
                startResendOtp();
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

    var otpResponse = await http.post(GConstants.otpVerifyRoute(), body: {
      'mobile_no': _mobileNumberTextController.text,
      'otp': _otpTextController.text
    });
    //print(otpResponse.body);

    if (otpResponse.statusCode == 200) {
      Map loginResponseObject = json.decode(otpResponse.body);
      debugPrint(loginResponseObject.toString());
      if (loginResponseObject.containsKey("status")) {
        if (loginResponseObject["status"] == "success") {
          int loginRecordId =
              await saveLoginReport(int.parse(loginResponseObject['login_id']));
          if (loginRecordId != 0) {
            loginResponseObject["login_record_id"] = loginRecordId;

            loginResponseObject.remove("status");
            loginResponseObject.remove("message");

            await AppData().saveUsersData(loginResponseObject);
            await AppData().setNormalSchoolRootUrlAndId(
                GConstants.SCHOOL_ROOT, _schoolIdTextController.text);
            hideProgressDialog();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (BuildContext context) {
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

    var otpResponse = await http.post(GConstants.resendOtpRoute(),
        body: {'mobile_no': _mobileNumberTextController.text});
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
    var loginReportResponse = await http.post(GConstants.loginReportRoute(),
        body: {'login_id': loginId.toString(), 'event': "in"});
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

  void startResendOtp() {
    _start = 30;
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        if (_start < 1) {
          _timer.cancel();
        } else {
          _start = _start - 1;
        }
        if (_start < 1) {
          _resendOtpLabel = "Didn't receive the OTP, ";
        } else {
          _resendOtpLabel = "Please wait for $_start seconds";
        }
      });
    });
  }

  _impersonationLogic() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) =>
                ImpersonationMain(_schoolIdTextController.text)));
  }

  bool authCompleted = false;
  String _verificationId;
  FirebaseAuth _firebaseAuth;


  void _verifyPhoneNumber() async {
    authCompleted = false;
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      authCompleted = true;
      try {
        hideProgressDialog();
      } catch (e) {}
      _signInWithPhoneNumber(phoneAuthCredential);
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      hideProgressDialog();
      _scaffoldState.currentState?.showSnackBar(SnackBar(
        content: Text("Firebase auth error"),
      ));
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      _verificationId = verificationId;
      //sendOtp.value = true;
      hideProgressDialog();
      setState(() {
        _showOtpUi = true;
      });
      _scaffoldState.currentState?.showSnackBar(SnackBar(
        content: Text("OTP has been sent"),
      ));
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
    };

    await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: "+91${_mobileNumberTextController.text}",
        timeout: const Duration(seconds: 60),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  void _signInWithPhoneNumber(AuthCredential crendials) async {
    showProgressDialog();
    try {
     _afterFirebaseAuthRoutine();
    } catch (e) {
      hideProgressDialog();
      _scaffoldState?.currentState?.showSnackBar(SnackBar(
        content: Text("Wrong OTP"),
      ));
    }
  }


  void _afterFirebaseAuthRoutine() async {
    showProgressDialog();

    var otpResponse = await http.post(GConstants.afterFirebaseAuthRoute(), body: {
      'mobile_no': _mobileNumberTextController.text,
    });
    //print(otpResponse.body);

    if (otpResponse.statusCode == 200) {
      Map loginResponseObject = json.decode(otpResponse.body);
      if (loginResponseObject.containsKey("status")) {
        if (loginResponseObject["status"] == "success") {
          int loginRecordId =
          await saveLoginReport(int.parse(loginResponseObject['login_id']));
          if (loginRecordId != 0) {
            loginResponseObject["login_record_id"] = loginRecordId;

            loginResponseObject.remove("status");
            loginResponseObject.remove("message");

            await AppData().saveUsersData(loginResponseObject);
            await AppData().setNormalSchoolRootUrlAndId(
                GConstants.SCHOOL_ROOT, _schoolIdTextController.text);
            hideProgressDialog();
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (BuildContext context) {
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
              SizedBox.expand(
                  child:
                      Image.asset("assets/main_back.jpg", fit: BoxFit.cover)),
              Opacity(
                  opacity: 0.8,
                  child: Container(color: Colors.indigo.shade900)),
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
                                  child: Column(
                                      children: <Widget>[
                                        Icon(Icons.vpn_key,
                                            size: 80, color: Colors.white),
                                        Padding(
                                            padding: EdgeInsets.all(0),
                                            child: Text("",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold)))
                                      ],
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start)))
                          : Container(height: 0),
                      Container(height: 10),
                      Stack(
                        children: <Widget>[
                          SvgPicture.asset("assets/abc.svg", width: 370),
                          Container(
                            padding: EdgeInsets.fromLTRB(20, 30, 60, 0),
                            child: Column(
                              children: <Widget>[
                                Text(_showOtpUi ? "ENTER OTP" : "LOGIN PLEASE",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade600)),
                                SizedBox(
                                  width: 300,
                                  child: Form(
                                      child: TextFormField(
                                          enabled: !_showOtpUi,
                                          decoration: InputDecoration(
                                              labelText: "School ID",
                                              contentPadding:
                                                  EdgeInsets.fromLTRB(
                                                      0, 16, 0, 2),
                                              labelStyle:
                                                  TextStyle(fontSize: 14)),
                                          maxLines: 1,
                                          keyboardType:
                                              TextInputType.numberWithOptions(),
                                          scrollPadding: EdgeInsets.all(0),
                                          validator: (txt) {
                                            if (txt.length != 3) {
                                              return 'Invalid ID';
                                            }
                                            Pattern pattern = "\\d+";
                                            RegExp regex = new RegExp(pattern);
                                            if (!regex.hasMatch(txt))
                                              return 'Invalid number';
                                            else
                                              return null;
                                          },
                                          controller: _schoolIdTextController)),
                                ),
                                SizedBox(
                                  width: 300,
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                          child: Form(
                                              key: _formKey,
                                              child: TextFormField(
                                                  enabled: !_showOtpUi,
                                                  decoration: InputDecoration(
                                                      labelText:
                                                          "Enter your mobile number",
                                                      contentPadding:
                                                          EdgeInsets.fromLTRB(
                                                              0, 16, 0, 2),
                                                      labelStyle: TextStyle(
                                                          fontSize: 14)),
                                                  maxLines: 1,
                                                  keyboardType: TextInputType
                                                      .numberWithOptions(),
                                                  scrollPadding:
                                                      EdgeInsets.all(0),
                                                  validator: (txt) {
                                                    if (txt.length != 10) {
                                                      return 'Invalid number';
                                                    }
                                                    Pattern pattern = "\\d+";
                                                    RegExp regex =
                                                        new RegExp(pattern);
                                                    if (!regex.hasMatch(txt))
                                                      return 'Invalid number';
                                                    else
                                                      return null;
                                                  },
                                                  controller:
                                                      _mobileNumberTextController))),
                                      _showOtpUi
                                          ? IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () {
                                                setState(() {
                                                  _showOtpUi = false;
                                                });
                                                _timer.cancel();
                                              })
                                          : Container(width: 0)
                                    ],
                                  ),
                                ),
                                _showOtpUi
                                    ? SizedBox(
                                        width: 250,
                                        child: Container(
                                            child: Form(
                                                key: _formKeyOtp,
                                                child: TextFormField(
                                                    autofocus: true,
                                                    decoration: InputDecoration(
                                                        hintText: "Enter OTP",
                                                        contentPadding:
                                                            EdgeInsets.fromLTRB(
                                                                0, 16, 0, 2),
                                                        focusedBorder:
                                                            UnderlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: Colors
                                                                        .grey)),
                                                        enabledBorder:
                                                            UnderlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: Colors
                                                                        .grey)),
                                                        alignLabelWithHint:
                                                            true,
                                                        hintStyle: TextStyle(
                                                            fontSize: 12),
                                                        errorStyle: TextStyle(
                                                            fontSize: 10)),
                                                    maxLines: 1,
                                                    textAlign: TextAlign.center,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    scrollPadding:
                                                        EdgeInsets.all(0),
                                                    style: TextStyle(color: Colors.grey),
                                                    validator: (txt) {
                                                      if(txt.isEmpty){
                                                        return "  Invalid OTP";
                                                      }
                                                      return null;
                                                    },
                                                    controller: _otpTextController)),
                                            padding: EdgeInsets.fromLTRB(0, 20, 0, 20)))
                                    : Container(height: 40),
                                Container(height: 20),
                                SizedBox(
                                    width: 290,
                                    child: Align(
                                        child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                                minWidth: 150, maxHeight: 30),
                                            child: RaisedButton(
                                                onPressed: () {
                                                  if (_showOtpUi) {
                                                    if (_formKeyOtp.currentState
                                                        .validate()) {
                                                      if(_verificationId != null){
                                                        final AuthCredential credential = PhoneAuthProvider.getCredential(
                                                          verificationId: _verificationId,
                                                          smsCode: _mobileNumberTextController.text,
                                                        );
                                                        _signInWithPhoneNumber(credential);
                                                      }else{
                                                        _otpVerifyRequest();
                                                      }
                                                    }
                                                  } else {
                                                    if (_formKey.currentState
                                                        .validate()) {
                                                      if (_mobileNumberTextController
                                                              .text ==
                                                          "9876543210") {
                                                        _impersonationLogic();
                                                      } else {
                                                        _loginRequest();
                                                      }
                                                    }
                                                  }
                                                },
                                                child: Text(
                                                    _showOtpUi
                                                        ? "VERIFY OTP"
                                                        : "REQUEST OTP",
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                color: Colors.pink)),
                                        alignment: Alignment.center)),
                                Container(height: 10),
                                _showOtpUi
                                    ? SizedBox(
                                        width: 300,
                                        child: Align(
                                            alignment: Alignment.center,
                                            child: Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    0, 10, 0, 0),
                                                child: RichText(
                                                    textAlign: TextAlign.center,
                                                    text: TextSpan(children: <
                                                        TextSpan>[
                                                      TextSpan(
                                                          text: _resendOtpLabel,
                                                          style: TextStyle(
                                                              color: Colors.grey
                                                                  .shade700,
                                                              fontSize: 12)),
                                                      _start < 1
                                                          ? _LinkTextSpan(this,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .indigo,
                                                                  fontSize: 12),
                                                              url: 'RESEND OTP')
                                                          : TextSpan(
                                                              text: '',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade700,
                                                                  fontSize: 12))
                                                    ])))))
                                    : Container(height: 0)
                              ],
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                            ),
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
                                      String url =
                                          await DbSchoolInfo().getFacebookUrl();
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
                                      String url =
                                          await DbSchoolInfo().getEmail();
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
                                      String url =
                                          await DbSchoolInfo().getWebUr();
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
                                      String url =
                                          await DbSchoolInfo().getPhone();
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
                                      await launch(
                                          "https://wa.me/918009121315");
                                    })
                              ],
                              mainAxisAlignment: MainAxisAlignment.center,
                            ),
                            Container(
                              height: 40,
                            ),
                            Text(
                              "Powered by Stucare Technologies Pvt. Ltd.",
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10),
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
    _firebaseAuth = FirebaseAuth.instance;
    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        setState(() {
          _isKeyboardVisible = visible;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
      await showDialog(
              context: context,
              builder: (BuildContext context) => dialog,
              barrierDismissible: false)
          .then((value) async {
        await AppData().setNormalSchoolRootUrlAndId(
            value['url'], value['school_id'].toString());
        await GConstants.getSchoolUrl();
      });
    }
  }
}
