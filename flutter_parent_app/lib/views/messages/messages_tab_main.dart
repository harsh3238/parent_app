import 'package:click_campus_parent/views/messages/messages_main.dart';
import 'package:flutter/material.dart';

import 'announcement_timeline.dart';

class MessageTabMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(
                text: "Announcements",
              ),
              Tab(text: "Teacher Wise"),
            ],
          ),
          title: Text('Messages'),
        ),
        body: TabBarView(
          children: [
            Announcement(),
            MessagesMainFragment(),
          ],
        ),
      ),
    );
  }
}
