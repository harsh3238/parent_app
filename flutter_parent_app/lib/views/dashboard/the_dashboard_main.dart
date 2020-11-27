import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/custom_views/custom_navigation_item.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/session_db_provider.dart';
import 'package:click_campus_parent/views/dashboard/frg_home.dart';
import 'package:click_campus_parent/views/login/select_impersonation.dart';
import 'package:click_campus_parent/views/messages/messages_tab_main.dart';
import 'package:click_campus_parent/views/profile/profile_one_page.dart';
import 'package:click_campus_parent/views/splash/splash_screen.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../../main.dart';

class DashboardMain extends StatefulWidget {
  final bool skipSessionValidation;

  DashboardMain(this.skipSessionValidation);

  @override
  DashboardMainState createState() => DashboardMainState();
}

class DashboardMainState extends State<DashboardMain>
    with TickerProviderStateMixin, StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  int _currentIndex = 0;
  BottomNavigationBarType _type = BottomNavigationBarType.fixed;
  List<NavigationIconView> _navigationViews;
  List<Widget> dashboardScreens;
  bool _firstRunRoutineRan = false;
  Set<int> seenMessages = Set();
  int unreadMessages = 0;

  FragmentHome _homeFragment;

  void _validateLogIn() async {
    if (widget.skipSessionValidation) {
      _getSessions();
      return null;
    }
    showProgressDialog();

    int userLoginId = await AppData().getUserLoginId();
    String sessionToken = await AppData().getSessionToken();
    var sId = await GConstants.schoolId();
    var loginResponse = await http.post(GConstants.validateLoginRoute(), body: {
      'login_id': userLoginId.toString(),
      'active_session': sessionToken,
      'school_id': sId.toString()
    });

    debugPrint("${loginResponse.request} : ${loginResponse.body}");

    if (loginResponse.statusCode == 200) {
      if(loginResponse.body == "auth error"){
        showSessionDialog("Session Expired");
      }
      Map loginResponseObject = json.decode(loginResponse.body);
      if (loginResponseObject.containsKey("status")) {
        if (loginResponseObject["status"] == "success") {
          _getSessions();
          return null;
        } else {
          hideProgressDialog();
          showSessionDialog(loginResponseObject["message"]);
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

  void _getSessions() async {
    String sessionToken = await AppData().getSessionToken();

    var modulesResponse = await http.post(GConstants.getSessionsRoute(), body: {
      'active_session': sessionToken,
    });

    debugPrint("${modulesResponse.request} : ${modulesResponse.body}");

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
          List<dynamic> modulesData = modulesResponseObject['data'];
          await SessionDbProvider().insertSession(modulesData);
          _getSiblings();
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

  void _getSiblings() async {
    int userLoginId = await AppData().getUserLoginId();
    String sessionToken = await AppData().getSessionToken();

    var siblingsResponse =
        await http.post(GConstants.getSiblingsRoute(), body: {
      'login_row_id': userLoginId.toString(),
      'active_session': sessionToken,
    });

    debugPrint("${siblingsResponse.request} : ${siblingsResponse.body}");

    if (siblingsResponse.statusCode == 200) {
      Map siblingsResponseObject = json.decode(siblingsResponse.body);
      if (siblingsResponseObject.containsKey("status")) {
        if (siblingsResponseObject["status"] == "success") {
          hideProgressDialog();
          List<dynamic> studentList = siblingsResponseObject['siblings'];
          if (studentList.length > 1) {
            var dialog = SimpleDialog(
              title: const Text('Please Select Student'),
              children: getStudentList(studentList),
            );
            showDialog(
                    context: context,
                    builder: (BuildContext context) => dialog,
                    barrierDismissible: false)
                .then((value) {
              //print("SELECTED stucare ID = $value");
              AppData().setSelectedStudent(int.parse(value[0]));
              AppData().setSelectedStudentName(value[1]);
              _homeFragment.refresh(true);
              //_getActiveModules();
            });
          } else if (studentList.length == 1) {
            Map<String, dynamic> singleStu = studentList[0];
            //print("SELECTED stucare ID = ${singleStu['stucare_id']}");
            AppData().setSelectedStudent(int.parse(singleStu['stucare_id']));
            AppData().setSelectedStudentName(singleStu['stu_fname']);
            _homeFragment.refresh(true);
          }
          return null;
        } else {
          await AppData().deleteAllUsers();
          await StateSelectImpersonation.saveImpersonationStatus(null, null);
          hideProgressDialog();
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return Scaffold(
              body: SplashScreen(),
            );
          }));
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

  List<Widget> getStudentList(List<dynamic> students) {
    List<Widget> widgets = List();
    for (Map<String, dynamic> aStudent in students) {
      widgets.add(SimpleDialogOption(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            aStudent['stu_fname'],
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
        onPressed: () {
          Navigator.pop(
              context, [aStudent['stucare_id'], aStudent['stu_fname']]);
        },
      ));
    }
    return widgets;
  }


  void _setFirebaseId(String firebaseToken) async {
    int userLoginId = await AppData().getUserLoginId();
    String sessionToken = await AppData().getSessionToken();

    var firebaseIdUploadRs = await http.post(GConstants.getSetFirebaseIdRoute(),
        body: {
          'login_id': userLoginId.toString(),
          'firebase_id': firebaseToken,
          'active_session': sessionToken,
        });
    //print(firebaseIdUploadRs.body);
  }

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void setUpFirebase() {
    if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.getToken().then((token) {
      //print("FIREBASE ID = " + token);
      _setFirebaseId(token);
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        //print('on message $message');
        _showNotification(
            message['notification']['title'], message['notification']['body']);
      },
      onResume: (Map<String, dynamic> message) async {
        checkIfNotificationIsLowPrioritySms(message);
      },
      onLaunch: (Map<String, dynamic> message) async {
        checkIfNotificationIsLowPrioritySms(message);
      },
    );
  }

  void iOS_Permission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      //print("Settings registered: $settings");
    });
  }


  Future<void> _showNotification(String title, String body) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }

  Future<void> checkIfNotificationIsLowPrioritySms(
      Map<String, dynamic> payload) async {
    //print('on launch $payload');
    Map<dynamic, dynamic> data = payload['data'];
    //print('on launch ${data.keys}');
    if (data != null &&
        data.containsKey('intent') &&
        data['intent'] == 'low_priority_sms') {
      seenMessages.add(int.parse(data['message_id']));
      //print("SEEN MESSAGES = ${seenMessages.toString()}");
    }
    if (seenMessages.length > 0) {
      updateSeenMessages();
    }
    return null;
  }

  void updateSeenMessages() async {
    int userStucareId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var loginResponse =
        await http.post(GConstants.getUpdateSeenMessagesRoute(), body: {
      'emp_stucare_id': userStucareId.toString(),
      'message_id': jsonEncode(seenMessages.toList()).toString(),
          'active_session': sessionToken,
    });

    //print(loginResponse.body);

    if (loginResponse.statusCode == 200) {
      Map loginResponseObject = json.decode(loginResponse.body);
      if (loginResponseObject.containsKey("status")) {
        if (loginResponseObject["status"] == "success") {}
      }
    }
  }

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState);
    setUpFirebase();

    _firstRunRoutineRan = false;

    _homeFragment = FragmentHome();
    dashboardScreens = <Widget>[
      _homeFragment,
      MessageTabMain(),
      ProfileOnePage(),
      Container(
        color: Colors.purpleAccent,
      )
    ];

    /*for (NavigationIconView view in _navigationViews)
      view.controller.addListener(rebuild);

    _navigationViews[_currentIndex].controller.value = 1.0;*/
  }

  @override
  void dispose() {
    for (NavigationIconView view in _navigationViews) view.controller.dispose();
    super.dispose();
  }

  void rebuild() {
    setState(() {
      // Rebuild in order to animate views.
    });
  }

  Widget _buildTransitionsStack() {
    final List<FadeTransition> transitions = <FadeTransition>[];

    for (NavigationIconView view in _navigationViews)
      transitions.add(view.transition(_type, context));

    // We want to have the newly animating (fading in) views on top.
    transitions.sort((FadeTransition a, FadeTransition b) {
      final Animation<double> aAnimation = a.opacity;
      final Animation<double> bAnimation = b.opacity;
      final double aValue = aAnimation.value;
      final double bValue = bAnimation.value;
      return aValue.compareTo(bValue);
    });

    return Stack(children: transitions);
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstRunRoutineRan) {
      _firstRunRoutineRan = true;
      Future.delayed(Duration(milliseconds: 100), () async {
        _validateLogIn();
      });
    }
    _navigationViews = <NavigationIconView>[
      NavigationIconView(
          icon: const Icon(Icons.home),
          title: 'Home',
          vsync: this,
          unreadMessages: unreadMessages),
      NavigationIconView(
          icon: const Icon(Icons.mail),
          title: 'Messages',
          vsync: this,
          unreadMessages: unreadMessages),
      NavigationIconView(
          icon: const Icon(Icons.person),
          title: 'Profile.',
          vsync: this,
          unreadMessages: unreadMessages)
    ];

    final BottomNavigationBar botNavBar = BottomNavigationBar(
      items: _navigationViews
          .map<BottomNavigationBarItem>(
              (NavigationIconView navigationView) => navigationView.item)
          .toList(),
      currentIndex: _currentIndex,
      type: _type,
      onTap: (int index) {
        //print("SEEN MESSAGES = ${seenMessages.toString()}");
        if (index != 1 && seenMessages.length > 0) {
          updateSeenMessages();
        }
        setState(() {
          _navigationViews[_currentIndex].controller.reverse();
          _currentIndex = index;
          _navigationViews[_currentIndex].controller.forward();
        });
      },
    );

    return Scaffold(
      key: _scaffoldState,
      body: FullAdmissionRootView(
        child: Center(child: dashboardScreens[_currentIndex]),
        state: this,
      ),
      bottomNavigationBar: botNavBar,
    );
  }

  void showSessionDialog(String msg) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Authentication Failed"),
            content: Text(msg+", Please login again to continue using app"),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                  _logOutUser();
                },
                child: Text("Login"),
              )
            ],
          );
        });

  }

  void _logOutUser() async {
    showProgressDialog();
    Future.delayed(Duration(milliseconds: 1500), () async {
      await AppData().deleteAllUsers();
      await AppData().clearSharedPrefs();
      await StateSelectImpersonation.saveImpersonationStatus(null, null);
      hideProgressDialog();
      //Navigator.pop(context);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (BuildContext context) {
            return Scaffold(
              body: SplashScreen(),
            );
          }));
    });
  }

}

class FullAdmissionRootView extends InheritedWidget {
  FullAdmissionRootView({
    Key key,
    this.state,
    Widget child,
  }) : super(key: key, child: child);

  final DashboardMainState state;

  @override
  bool updateShouldNotify(FullAdmissionRootView oldWidget) =>
      state != oldWidget.state;

  static FullAdmissionRootView of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FullAdmissionRootView>();
  }
}
