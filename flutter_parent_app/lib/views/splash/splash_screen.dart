import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/db_school_info.dart';
import 'package:click_campus_parent/views/dashboard/the_dashboard_main.dart';
import 'package:click_campus_parent/views/login/login.dart';
import 'package:click_campus_parent/views/login/select_impersonation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends StatelessWidget {
  BuildContext _context;
  bool areWeDone = false;

  void _getSchoolInfo() async {
    await GConstants.getSchoolUrl();

    var sId = await GConstants.schoolId();

    var modulesResponse = await http.post(GConstants.getSchoolInfoRoute(),
        body: {'school_id': sId.toString()});

    //print("http:= " +modulesResponse.body);

    int newAppVersion;

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
          Map<String, dynamic> modulesData = modulesResponseObject['data'];
          var v = modulesData['app_version'];
          newAppVersion = int.parse(v ?? '0');
          await DbSchoolInfo().insertSchoolInfo(modulesData);
        }
      }
    }

    if (areWeDone) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String buildNumber = packageInfo.buildNumber;
      String packageName = packageInfo.packageName;
      if (int.parse(buildNumber) < newAppVersion) {
        showDialog(
            context: _context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("App Update Available"),
                content: Text(
                    'A newer version of the app is available and must be installed in order to continue using the app.'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      Navigator.pop(context, 0);
                    },
                    child: Text("Download"),
                  ),
                  FlatButton(
                    onPressed: () {
                      Navigator.pop(context, 1);
                    },
                    child: Text("Later"),
                  )
                ],
              );
            }).then((v) {
          if (v == 0) {
            _launchURL(
                "https://play.google.com/store/apps/details?id=$packageName");
            SystemNavigator.pop();
          } else {
            _whatScreenToLauch();
          }
        });
      } else {
        _whatScreenToLauch();
      }
    } else {
      Future.delayed(Duration(seconds: 1), () async {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String buildNumber = packageInfo.buildNumber;
        String packageName = packageInfo.packageName;
        if (int.parse(buildNumber) < newAppVersion) {
          showDialog(
              context: _context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("App Update Available"),
                  content: Text(
                      'A newer version of the app is available and must be installed in order to continue using the app.'),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () {
                        Navigator.pop(context, 0);
                      },
                      child: Text("Download"),
                    ),
                    FlatButton(
                      onPressed: () {
                        Navigator.pop(context, 1);
                      },
                      child: Text("Later"),
                    )
                  ],
                );
              }).then((v) {
            if (v == 0) {
              _launchURL(
                  "https://play.google.com/store/apps/details?id=$packageName");
              SystemNavigator.pop();
            } else {
              _whatScreenToLauch();
            }
          });
        } else {
          _whatScreenToLauch();
        }
      });
    }
  }

  void _whatScreenToLauch() async {
    var permission = await _checkPermission();
    if(!permission){
      SystemNavigator.pop();
      return;
    }

    var rWeLoggedIn = await AppData().areWeLoggedIn();
    if (!rWeLoggedIn) {
      Navigator.pushReplacement(
          _context,
          MaterialPageRoute(
            builder: (BuildContext context) => LoginScreen(),
          ));
    } else {
      var impersonatedSchool = await AppData().getImpersonatedSchool();
      var stucareEmpId = await AppData().getStucareEmpId();
      if (impersonatedSchool != null) {
        Navigator.pushReplacement(
            _context,
            MaterialPageRoute(
                builder: (BuildContext context) =>
                    SelectImpersonation(impersonatedSchool, stucareEmpId)));
      } else {
        Navigator.pushReplacement(
            _context,
            MaterialPageRoute(
              builder: (BuildContext context) =>
                  DashboardMain(false),
            ));
      }
    }
  }

  Future<bool> _checkPermission() async {
    if (Theme.of(_context).platform == TargetPlatform.android) {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage);
      if (permission != PermissionStatus.granted) {
        Map<PermissionGroup, PermissionStatus> permissions =
        await PermissionHandler()
            .requestPermissions([PermissionGroup.storage]);
        if (permissions[PermissionGroup.storage] == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  _launchURL(String theUrl) async {
    if (await canLaunch(theUrl)) {
      await launch(theUrl);
    } else {
      throw 'Cannot open browser for this $theUrl';
    }
  }

  SplashScreen({Key key}) : super(key: key) {
    _getSchoolInfo();
    Future.delayed(Duration(seconds: 2), () async {
      areWeDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Container(
      child: Stack(fit: StackFit.loose, children: <Widget>[
        SizedBox.expand(
          child: Image.asset(
            "assets/main_back.jpg",
            fit: BoxFit.cover,
          ),
        ),
        Opacity(
          opacity: 0.8,
          child: Container(
            color: Colors.indigo.shade900,
          ),
        ),
        Center(
          child: Text(
            "",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        Positioned(
          child: Center(
            child: Container(
              width: 150,
              height: 1,
              child: LinearProgressIndicator(),
            ),
          ),
          bottom: 100,
          left: 0,
          right: 0,
        ),
        Positioned(
          child: Center(
            child: Text(
              "Powered by Stucare Technologies Pvt. Ltd.",
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          bottom: 20,
          left: 0,
          right: 0,
        )
      ]),
    );
  }
}