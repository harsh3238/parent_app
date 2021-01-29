import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/data/db_school_info.dart';
import 'package:click_campus_parent/views/attendance/attendance_main.dart';
import 'package:click_campus_parent/views/dashboard/marquee_widget.dart';
import 'package:click_campus_parent/views/dashboard/the_dashboard_main.dart';
import 'package:click_campus_parent/views/downloads/downloads_main.dart';
import 'package:click_campus_parent/views/events/events_main.dart';
import 'package:click_campus_parent/views/exams/exams_main.dart';
import 'package:click_campus_parent/views/fee/fee_main.dart';
import 'package:click_campus_parent/views/fitness_report/fitness_report_screen.dart';
import 'package:click_campus_parent/views/homework/homework_main.dart';
import 'package:click_campus_parent/views/leave/leave_main.dart';
import 'package:click_campus_parent/views/news/news_main.dart';
import 'package:click_campus_parent/views/notifications/notification_main.dart';
import 'package:click_campus_parent/views/online_classes/online_classes_tab_main.dart';
import 'package:click_campus_parent/views/photo_gallery/photo_gallery_main.dart';
import 'package:click_campus_parent/views/polls/polls.dart';
import 'package:click_campus_parent/views/references/references_main_list.dart';
import 'package:click_campus_parent/views/remark/student_remark_main.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:click_campus_parent/views/syllabus/syllabus_main.dart';
import 'package:click_campus_parent/views/teachers/teachers_main.dart';
import 'package:click_campus_parent/views/timetable/timetable_main.dart';
import 'package:click_campus_parent/views/video_gallery/video_gallery_main.dart';
import 'package:click_campus_parent/views/voice_calls/voice_call_main.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'flyer_dialog.dart';

class FragmentHome extends StatefulWidget {
  static const String routeName = '/material/bottom_navigation';

  FragmentHomeState _state;
  bool _shouldGetDataAfterDispose = false;
  bool _shouldShowFlyer = true;

  @override
  FragmentHomeState createState() {
    _state = FragmentHomeState();
    return _state;
  }

  void refresh(bool shouldGetData) {
    _shouldGetDataAfterDispose = false;
    if (shouldGetData) {
      _state._getActiveModules();
    }
  }
}

class DashItem {
  String itemName;
  String itemIdentifier;
  String iconPath;
  Color color;
  bool isCollapseExpandButton = false;

  DashItem(this.itemName, this.itemIdentifier, this.iconPath, this.color,
      this.isCollapseExpandButton);

  factory DashItem.fromJson(Map<String, dynamic> parsedJson) {
    return DashItem(
        parsedJson['name_to_show'],
        parsedJson['module_name'],
        "assets/dash_icons/${parsedJson['icon_name']}",
        Color(int.parse(parsedJson['color'])),
        false);
  }
}

class FragmentHomeState extends State<FragmentHome> with StateHelper {
  static const platform =
      const MethodChannel('com.stucare.cloud_parent/flutter_method_channel');
  List<DashItem> items = List();
  List<dynamic> _dashSliders = List();
  String _bannerUrl = '';
  List<dynamic> _flyers = List();
  List<dynamic> _flashNews = List();

  String gridState = "collapsed";

  PageController _pageController =
      PageController(initialPage: 0, keepPage: false);

  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  int _unseenHomework = 0;

  void setFlipLoginInfo() async {
    var directory = await ExtStorage.getExternalStorageDirectory();
    final savedDir = Directory(directory + '/stucare');
    bool hasExisted = await savedDir.exists();
    savedDir.create();
    var path = savedDir.path;

    var file = File('$path/event.stucare');
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    var id =
        "${androidInfo.manufacturer}${androidInfo.model}${androidInfo.device}${androidInfo.board}";

    String mobileNumber = await AppData().getLoggedInUsersPhone();
    int userStucareId = await AppData().getSelectedStudent();
    var sId = await GConstants.schoolId();

    var uInfo = "$mobileNumber-$userStucareId-$sId";

    var bytes = utf8.encode(id);
    var digest = sha512.convert(bytes);
    var fString = "${digest.toString()}-$uInfo";
    // //print("DIGEST = ${fString}");
    file.writeAsString(fString.toString());
    String contents = await file.readAsString();
    // //print("DIGEST READ = ${contents}");
  }

  void _disableFLip() async {
    int userStucareId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();
    var sId = await GConstants.schoolId();
    var loginResponse =
        await http.post(GConstants.getDisbaleFLipRoute(), body: {
      'stucare_id': userStucareId.toString(),
      'active_session': sessionToken,
      'school_id': sId.toString()
    });
    debugPrint("${loginResponse.request} : ${loginResponse.body}");
  }

  void _getActiveModules() async {
    showProgressDialog();
    //setFlipLoginInfo();
    String secretKey = await AppData().getSecretKey();
    String accessKey = await AppData().getAccessKey();

    var sId = await GConstants.schoolId();
    String sessionToken = await AppData().getSessionToken();
    debugPrint("STORED_TOKEN:" + sessionToken);

    var modulesResponse =
        await http.post(GConstants.getActiveModulesRoute(), body: {
      'school_id': sId.toString(),
      'active_session': sessionToken,
    });

    log("${modulesResponse.request} : ${modulesResponse.body}");

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);

      String response = modulesResponse.body;
      if (response == "auth error") {
        hideProgressDialog();
        return;
      }

      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
          List<dynamic> modulesData = modulesResponseObject['data'];
          for (int i = 0; i < modulesData.length; i++) {
            items.add(DashItem.fromJson(modulesData[i]));
          }
          _disableFLip();
          _getSliders();
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

  void _getSliders() async {
    String sessionToken = await AppData().getSessionToken();

    var dashSlidersResponse =
        await http.post(GConstants.getDashSliderRoute(), body: {
      'active_session': sessionToken,
    });

    log("${dashSlidersResponse.request} : ${dashSlidersResponse.body}");

    if (dashSlidersResponse.statusCode == 200) {
      Map dashSlidersResponseObject = json.decode(dashSlidersResponse.body);
      if (dashSlidersResponseObject.containsKey("status")) {
        if (dashSlidersResponseObject["status"] == "success") {
          _dashSliders = dashSlidersResponseObject['data'];
          _bannerUrl = dashSlidersResponseObject['banner'];
          _getFlashNews();
          return null;
        } else {
          hideProgressDialog();
          showSnackBar(dashSlidersResponseObject["message"]);
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

  void _getFlashNews() async {
    String sessionToken = await AppData().getSessionToken();

    var dashSlidersResponse =
        await http.post(GConstants.getFlashNewsRoute(), body: {
      'active_session': sessionToken,
    });

    log("${dashSlidersResponse.request} : ${dashSlidersResponse.body}");

    if (dashSlidersResponse.statusCode == 200) {
      Map dashSlidersResponseObject = json.decode(dashSlidersResponse.body);
      if (dashSlidersResponseObject.containsKey("status")) {
        if (dashSlidersResponseObject["status"] == "success") {
          _flashNews = dashSlidersResponseObject['data'];
          _getSchoolInfo();
          return null;
        } else {
          hideProgressDialog();
          showSnackBar(dashSlidersResponseObject["message"]);
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

  void _getSchoolInfo() async {
    var sId = await GConstants.schoolId();

    var schoolInfoRs = await http.post(GConstants.getSchoolInfoRoute(),
        body: {'school_id': sId.toString()});

    debugPrint("${schoolInfoRs.request} : ${schoolInfoRs.body}");

    if (schoolInfoRs.statusCode == 200) {
      Map schoolInfoRsObject = json.decode(schoolInfoRs.body);
      if (schoolInfoRsObject.containsKey("status")) {
        if (schoolInfoRsObject["status"] == "success") {
          Map<String, dynamic> modulesData = schoolInfoRsObject['data'];

          if (modulesData.containsKey("access_key")) {
            AppData().setAccessKey(modulesData['access_key']);
            AppData().setSecretKey(modulesData['secrety_key']);
            modulesData.remove('access_key');
            modulesData.remove('secrety_key');
          }

          if (modulesData.containsKey("aws_bucket_name")) {
            AppData().setBucketName(modulesData['aws_bucket_name']);
            AppData().setBucketRegion(modulesData['aws_bucket_region']);
            AppData().setBucketUrl(modulesData['aws_bucket_url']);
            modulesData.remove('aws_bucket_name');
            modulesData.remove('aws_bucket_region');
            modulesData.remove('aws_bucket_url');
          }

          await DbSchoolInfo().insertSchoolInfo(modulesData);
          _getFlyers();
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

  void _getFlyers() async {
    var ok = FullAdmissionRootView.of(context);

    int userStucareId = await AppData().getSelectedStudent();
    int lastMsgId = await AppData().getLastMessageId();
    String sessionToken = await AppData().getSessionToken();

    var flyersResponse = await http.post(GConstants.getFlyersRoute(), body: {
      'stucare_id': userStucareId.toString(),
      'last_msg_id': lastMsgId.toString() ?? '',
      'active_session': sessionToken,
    });

    debugPrint("${flyersResponse.request} : ${flyersResponse.body}");

    if (flyersResponse.statusCode == 200) {
      Map flyersResponseObject = json.decode(flyersResponse.body);
      if (flyersResponseObject.containsKey("status")) {
        if (flyersResponseObject["status"] == "success") {
          _flyers = flyersResponseObject['data'];
          var unreadMsgs = flyersResponseObject['unread_messages'];
          ok.state.unreadMessages =
              unreadMsgs != null ? int.parse(unreadMsgs) : 0;
          ok.state.rebuild();
          _setUnseenHomework(flyersResponseObject['homework']);

          hideProgressDialog();
          if (_flyers.length > 0 && widget._shouldShowFlyer) {
            widget._shouldShowFlyer = false;
            showDialog(
              context: context,
              builder: (BuildContext context) => FlyerDialog(_flyers),
            );
          }
          setState(() {});
          return null;
        } else {
          hideProgressDialog();
          showSnackBar(flyersResponseObject["message"]);
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

  Future<void> _handleRefresh() async {
    items.clear();
    widget.refresh(true);
  }

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState);
  }

  @override
  void dispose() {
    widget._shouldGetDataAfterDispose = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._shouldGetDataAfterDispose) {
      Future.delayed(Duration(milliseconds: 100), () async {
        widget._shouldGetDataAfterDispose = false;
        _getActiveModules();
      });
    }
    return Scaffold(
        key: _scaffoldState,
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: <Widget>[bodyList(), gridView(), bodyListFooter()],
          ),
        ));
  }

  Widget bodyList() => SliverList(
          delegate:
              SliverChildBuilderDelegate((BuildContext context, int index) {
        return Stack(
          alignment: FractionalOffset.bottomCenter,
          children: <Widget>[
            _dashSliders.length > 0
                ? CarouselSlider(
                    height: MediaQuery.of(context).size.height / 3,
                    autoPlay: true,
                    viewportFraction: 1.0,
                    autoPlayInterval: Duration(seconds: 2),
                    items: _dashSliders.map((i) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            //height: 500,
                            child: CachedNetworkImage(
                              imageUrl: i['file_url'],
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                          /*child: Image.network(i['file_url'],
                                  fit: BoxFit.cover));*/
                        },
                      );
                    }).toList(),
                    pauseAutoPlayOnTouch: Duration(seconds: 2),
                  )
                : Container(
                    height: 250,
                  ),
            Container(
                height: 30,
                decoration: new BoxDecoration(
                    color: Colors.white,
                    borderRadius: new BorderRadius.only(
                        topLeft: const Radius.circular(10.0),
                        topRight: const Radius.circular(10.0))),
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(4),
                      child: ImageIcon(
                        AssetImage("assets/ic_megaphone.png"),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        child: IgnorePointer(
                          ignoring: true,
                          child: PageView.builder(
                            reverse: true,
                            controller: _pageController,
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, position) {
                              return Center(
                                  child: MarqueeWidget(
                                direction: Axis.horizontal,
                                child: Text(
                                  _flashNews[position],
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(color: Colors.blue.shade900),
                                ),
                                pageController: _pageController,
                                myIndex: position,
                                noOfNews: _flashNews.length,
                              ));
                            },
                            itemCount: _flashNews.length,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.indigo,
                      ),
                      onPressed: () {
                        double a = _pageController.page;
                        int cPage = a.floor();
                        if (cPage == _flashNews.length - 1) {
                          _pageController.jumpToPage(0);
                        } else {
                          _pageController
                              .jumpToPage(_pageController.page.floor() + 1);
                        }
                      },
                      padding: EdgeInsets.all(4),
                    )
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ))
          ],
        );
      }, childCount: 1));

  Widget bodyListFooter() => SliverList(
          delegate:
              SliverChildBuilderDelegate((BuildContext context, int index) {
        return Container(
          padding: EdgeInsets.all(10),
          height: 150,
          child: _bannerUrl.length > 0
              ? Image.network(
                  _bannerUrl,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 0,
                ),
        );
      }, childCount: 1));

  Widget gridView() {
    return SliverGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      childAspectRatio: 1,
      children: items.length > 0 ? getGridItems() : [],
    );
  }

  List<Widget> getGridItems() {
    List<DashItem> data;

    if (items[items.length - 1].isCollapseExpandButton) {
      items.removeLast();
    }
    if (gridState == "collapsed") {
      data = items.sublist(0, 11);
      data.add(DashItem("More", "more", "assets/dash_icons/ic_less.png",
          Colors.teal.shade900, true));
    } else {
      data = items;
      data.add(DashItem("Less", "less", "assets/dash_icons/ic_less.png",
          Colors.teal.shade900, true));
    }

    return data.map((DashItem item) {
      return FlatButton(
        onPressed: () {
          if (item.isCollapseExpandButton) {
            data.remove(item);
            setState(() {
              if (gridState == "collapsed") {
                gridState = "expanded";
              } else {
                gridState = "collapsed";
              }
            });
          } else {
            openModuleMappedPage(item.itemIdentifier);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Stack(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Image.asset(
                    item.iconPath,
                    color: item.color,
                    height: 30,
                  ),
                ),
                (item.itemName.contains("Homework") && _unseenHomework > 0)
                    ? Positioned(
                        top: 0.0,
                        right: 0,
                        child: Stack(
                          children: <Widget>[
                            Icon(Icons.brightness_1,
                                size: 16.0, color: Colors.red),
                            Positioned(
                              top: 1.0,
                              right: 4.0,
                              child: Text(_unseenHomework.toString(),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500)),
                            )
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 0,
                      )
              ],
            ),
            Text(
              item.itemName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
        color: Colors.white,
        shape: Border.all(width: 0.1),
        padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
      );
    }).toList();
  }

  void openModuleMappedPage(String moduleName) async {
    switch (moduleName) {
      case "fitness_declaration":
        navigateToModule(FitnessDeclaration());
        break;
      case "remark":
        navigateToModule(StudentRemarkMain());
        break;
      case "notifications":
        navigateToModule(NotificationsMain());
        break;
      case "homework":
        navigateToModule(Homework(_unseenHomework));
        setState(() {
          _unseenHomework = 0;
        });
        break;
      case "attendance":
        navigateToModule(AttendanceMain());
        break;
      case "timetable":
        navigateToModule(TimetableMain());
        break;
      case "fee":
        navigateToModule(FeeMain());
        break;
      case "events":
        navigateToModule(EventsMain());
        break;
      case "news":
        navigateToModule(NewsMain());
        break;
      case "teachers":
        navigateToModule(TeachersMain());
        break;
      case "gallery":
        navigateToModule(PhotoGallery());
        break;
      case "video_gallery":
        navigateToModule(VideoGalleryMain());
        break;
      case "voice_call":
        navigateToModule(VoiceCallMain());
        break;
      case "leave":
        navigateToModule(LeaveMain());
        break;
      case "facebook":
        String url = await DbSchoolInfo().getFacebookUrl();
        _launchURL(url);
        break;
      case "feedback":
        navigateToModule(dummyPage());
        break;
      case "website":
        String url = await DbSchoolInfo().getWebUrl();
        _launchURL(url);
        break;
      case "study_zone":
        openStudyModule();
        break;
      case "school_info":
        navigateToModule(dummyPage());
        break;
      case "syllabus":
        navigateToModule(SyllabusMain());
        break;
      case "news":
        navigateToModule(dummyPage());
        break;
      case "track":
        navigateToModule(dummyPage());
        break;
      case "polls":
        navigateToModule(PollsMain());
        break;
      case "references":
        navigateToModule(ReferencesMainList());
        break;
      case "exam":
        navigateToModule(ExamsMain());
        break;
      case "classmates":
        navigateToModule(dummyPage());
        break;
      case "live_class":
        if (Platform.isIOS) {
          navigateToModule(OnlineClassTabMain());
        } else {
          int sId = await GConstants.schoolId();
          int userStucareId = await AppData().getSelectedStudent();
          String sessionToken = await AppData().getSessionToken();
          String studentName = await AppData().getSelectedStudentName();
          String baseUrl = await AppData().getNormalSchoolUrl();

          var arguments = {
            "stucareid": userStucareId,
            "sessionToken": sessionToken,
            "schoolId": sId,
            "studentName": studentName,
            "baseUrl": baseUrl
          };
          platform
              .invokeMethod("startLiveClassActivity", arguments)
              .then((rs) {});
        }

        break;
      case "online_tests":
        int sId = await GConstants.schoolId();
        int userStucareId = await AppData().getSelectedStudent();
        String sessionToken = await AppData().getSessionToken();
        String baseUrl = await AppData().getNormalSchoolUrl();
        var arguments = {
          "stucareid": userStucareId,
          "sessionToken": sessionToken,
          "schoolId": sId,
          "baseUrl": baseUrl
        };
        platform
            .invokeMethod("startOnlineTestsActivity", arguments)
            .then((rs) {});
        break;
      case "video_lessons":
        int sId = await GConstants.schoolId();
        int userStucareId = await AppData().getSelectedStudent();
        String sessionToken = await AppData().getSessionToken();
        String baseUrl = await AppData().getNormalSchoolUrl();
        var arguments = {
          "stucareid": userStucareId,
          "sessionToken": sessionToken,
          "schoolId": sId,
          "baseUrl": baseUrl
        };
        platform
            .invokeMethod("startVideoLessonsActivity", arguments)
            .then((rs) {});
        break;
      case "downloads":
        navigateToModule(DownloadsMain());
        break;
    }
  }

  Widget dummyPage() => Container(color: Colors.blue);

  void navigateToModule(Widget module) {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return Scaffold(
        body: module,
      );
    })).then((v) {
      if (v != null) {
        _setHomeworkSeen(v);
      }
    });
  }

  void openStudyModule() async {
    String mobileNumber = await AppData().getLoggedInUsersPhone();
    int userStucareId = await AppData().getSelectedStudent();
    var sId = await GConstants.schoolId();

    try {
      AndroidIntent intent = AndroidIntent(
        action: 'org.flipacademy.dynamic_login',
        arguments: <String, dynamic>{
          'mobile': mobileNumber,
          'stucare_id': userStucareId.toString(),
          "school_id": sId.toString()
        },
      );
      await intent.launch();
    } on PlatformException catch (err) {
      _launchURL(
          "https://play.google.com/store/apps/details?id=org.flipacademy");
    }
  }

  _launchURL(String theUrl) async {
    if (await canLaunch(theUrl)) {
      await launch(theUrl);
    } else {
      throw 'Cannot open browser for this $theUrl';
    }
  }

  void _setUnseenHomework(Map<String, dynamic> data) async {
    int count = 0;
    if (data != null && data.containsKey("todays") && data['todays'] != null) {
      var tData = data['todays'] as Map<String, dynamic>;
      var tTime = DateTime.parse(tData['timestamp_created']);
      var local = await AppData().getHomeworkSeen("todays");
      if (local == null) {
        count += 1;
      } else {
        var savedTimeForSeenHomework = DateTime.parse(local);
        if (tTime.isAfter(savedTimeForSeenHomework)) {
          count += 1;
          await AppData().setHomeworkSeen(tData['timestamp_created']);
        }
      }
    }

    if (data.containsKey("yesterdays")) {
      var yData = data['yesterdays'] as Map<String, dynamic>;
      var yTime = DateTime.parse(yData['timestamp_created']);
      var local = await AppData().getHomeworkSeen("yesterday");
      if (local == null) {
        count += 1;
      } else {
        var savedTimeForSeenHomework = DateTime.parse(local);
        if (yTime.isAfter(savedTimeForSeenHomework)) {
          count += 1;
          await AppData().setHomeworkSeen(yData['timestamp_created']);
        }
      }
    }
    setState(() {
      _unseenHomework = count;
    });
  }

  Future<void> _setHomeworkSeen(Set<int> data) async {
    var studecarId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();

    var homeworkResponse =
        await http.post(GConstants.getHomeworkSeenRoute(), body: {
      'homework_id': jsonEncode(data.toList()),
      'stucare_id': studecarId.toString(),
      'active_session': sessionToken,
    });

    //print(homeworkResponse.body);
  }
}
