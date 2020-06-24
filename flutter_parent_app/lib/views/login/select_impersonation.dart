import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/views/dashboard/the_dashboard_main.dart';
import 'package:click_campus_parent/views/login/search_impersonation.dart';
import 'package:click_campus_parent/views/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state_helper.dart';

class SelectImpersonation extends StatefulWidget {
  final schooldId;
  final stucareEmpId;

  SelectImpersonation(this.schooldId, this.stucareEmpId);

  @override
  State<StatefulWidget> createState() {
    return StateSelectImpersonation();
  }
}

class StateSelectImpersonation extends State<SelectImpersonation>
    with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool _didGetData = false;
  String tempSchoolUrl;
  List<dynamic> _usersList = [];

  static Future<void> saveImpersonationStatus(
      String schoolId, String empId) async {
    await AppData().setImpersonatedSchoolId(schoolId);
    await AppData().setStucareEmpId(empId);
  }

  Future<void> _logout() async {
    await saveImpersonationStatus(null, null);
    await AppData().deleteAllUsers();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (BuildContext context) => SplashScreen()));
  }

  Future<void> _getUsersList() async {
    showProgressDialog();

    var schoolDataResponse = await http.post(GConstants.schoolDataRoute(),
        body: {'school_id': widget.schooldId});
    //print(schoolDataResponse.body);

    if (schoolDataResponse.statusCode == 200) {
      Map responseObject = json.decode(schoolDataResponse.body);
      if (responseObject.containsKey("id")) {
        tempSchoolUrl = responseObject["api_route_base"];

        var loginResponse =
            await http.post(GConstants.getUserListForSuperUser(tempSchoolUrl));

        //print(loginResponse.body);

        if (loginResponse.statusCode == 200) {
          Map loginResponseObject = json.decode(loginResponse.body);
          if (loginResponseObject.containsKey("status")) {
            if (loginResponseObject["status"] == "success") {
              _usersList = loginResponseObject['data'];
              hideProgressDialog();
              setState(() {});
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

  Future<void> _selectUser(Map<String, dynamic> userData) async {
    showProgressDialog();

    var loginResponse = await http
        .post(GConstants.getLoginAsRoute(tempSchoolUrl), body: {
      'login_id': userData['login_id'],
      'stucare_emp_id': widget.stucareEmpId
    });

    //print(loginResponse.body);

    if (loginResponse.statusCode == 200) {
      Map loginResponseObject = json.decode(loginResponse.body);
      if (loginResponseObject.containsKey("status")) {
        if (loginResponseObject["status"] == "success") {
          hideProgressDialog();
          GConstants.setSchoolRootUrl(tempSchoolUrl);
          await AppData().saveUsersData(userData);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => DashboardMain(true)));
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
      saveImpersonationStatus(widget.schooldId, widget.stucareEmpId);
      Future.delayed(Duration(milliseconds: 100), () async {
        _getUsersList();
      });
    }

    return Scaffold(
        key: _scaffoldState,
        appBar: AppBar(
          title: Text("Select User"),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              SearchImpersonation(
                                  widget.schooldId, widget.stucareEmpId)));
                }),
            FlatButton(
              child: Text(
                "LOGOUT",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _logout();
              },
            )
          ],
        ),
        body: CustomScrollView(
          slivers: <Widget>[
            SliverList(
                delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
              return Card(
                child: ListTile(
                  title: Text(_usersList[index]['name'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 12)),
                  subtitle: Text(
                    _usersList[index]['mobile_no'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12),
                  ),
                  dense: true,
                  onTap: () async {
                    Map<String, dynamic> ok = Map.from(_usersList[index]);
                    ok.remove('name');
                    ok['active_session'] = 'NA';
                    _selectUser(ok);
                  },
                ),
                elevation: 0,
              );
            }, childCount: _usersList.length)),
          ],
        ));
  }
}
