import 'dart:async';
import 'dart:convert';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/views/messages/message_detail.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MessagesMainFragment extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MessagesMainState();
  }
}

class MessagesMainState extends State<MessagesMainFragment> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool didGetData = false;
  List<dynamic> _msgData = List();

  Future<void> _getMessagesData() async {
    showProgressDialog();

    int userStucareId = await AppData().getSelectedStudent();
    String sessionToken = await AppData().getSessionToken();


    var modulesResponse = await http.post(GConstants.getMessageThreadsRoute(),
        body: {'stucare_id': userStucareId.toString(),
          'active_session': sessionToken,});

    //print(modulesResponse.body);

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("status")) {
        if (modulesResponseObject["status"] == "success") {
          _msgData = modulesResponseObject['data'];
          setState(() {});
          hideProgressDialog();
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

  Future<void> _handleRefresh() async {
    _getMessagesData();
  }

  Widget _buildFriendListTile(BuildContext context, int index) {
    return Expanded(child: Container());
    return new ListTile(
      leading: new Container(
        width: 50.0,
        height: 50.0,
        decoration: new BoxDecoration(
          image: new DecorationImage(
            image: new NetworkImage(_msgData[index]['sender_image'] ?? ""),
            fit: BoxFit.cover,
          ),
          borderRadius: new BorderRadius.all(new Radius.circular(40.0)),
          border: new Border.all(
            color: Colors.white,
            width: 2.0,
          ),
        ),
      ),
      title: new Text(_msgData[index]['sender_name']?? ""),
      subtitle: new Text(
        (_msgData[index]['message_media_type'] == 'Text') ? _msgData[index]['message_text'] : "Has Attachment",
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: new Text( DateFormat().addPattern("dd-MMM").format(DateTime.parse(_msgData[index]['date'])).toString()),
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (b) => MessageDetail(_msgData[index]['sender_name'], _msgData[index]['sender'])));
      },
    );
  }

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldKey);
  }

  @override
  Widget build(BuildContext context) {
    if (!didGetData) {
      Future.delayed(Duration(milliseconds: 100), () async {
        _getMessagesData();
        didGetData = true;
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: ListView.builder(
          itemCount: _msgData.length,
          itemBuilder: _buildFriendListTile,
        ),
      ),
    );
  }
}
