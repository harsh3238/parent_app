import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/views/dashboard/the_dashboard_main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../state_helper.dart';


class SearchImpersonation extends StatefulWidget {
  final schooldId;
  final stucareEmpId;

  SearchImpersonation(this.schooldId, this.stucareEmpId);

  @override
  State<StatefulWidget> createState() {
    return StateSearchImpersonation();
  }
}

class StateSearchImpersonation extends State<SearchImpersonation>
    with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  String tempSchoolUrl;
  List<dynamic> _usersList = [];

  static Future<void> saveImpersonationStatus(String schoolId, String empId) async {
    await AppData().setImpersonatedSchoolId(schoolId);
    await AppData().setStucareEmpId(empId);
  }

  Future<void> _getUsersList(String query) async {
    var schoolDataResponse = await http.post(GConstants.schoolDataRoute(),
        body: {'school_id': widget.schooldId});
    //print(schoolDataResponse.body);

    if (schoolDataResponse.statusCode == 200) {
      Map responseObject = json.decode(schoolDataResponse.body);
      if (responseObject.containsKey("id")) {
        tempSchoolUrl = responseObject["api_route_base"];


        var loginResponse =
            await http.post(GConstants.getUserListForSuperUser(tempSchoolUrl), body: {
              'query': query
            });

        //print(loginResponse.body);

        if (loginResponse.statusCode == 200) {
          Map loginResponseObject = json.decode(loginResponse.body);
          if (loginResponseObject.containsKey("status")) {
            if (loginResponseObject["status"] == "success") {
              _usersList = loginResponseObject['data'];
              setState(() {});
            }
          }
        }
      }
    }
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

  final TextEditingController _filter = new TextEditingController();

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
    _filter.addListener(() async {
      if(_filter.text.length > 3){
        _getUsersList(_filter.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldState,
        appBar: AppBar(
          centerTitle: true,
          title: Theme(
              data: ThemeData(
                  accentColor: Colors.white,
                  primaryColor: Colors.white,
                  focusColor: Colors.white),
              child: TextField(
                controller: _filter,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search...',
                ),
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white),
              )),
          leading: IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              }),
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
