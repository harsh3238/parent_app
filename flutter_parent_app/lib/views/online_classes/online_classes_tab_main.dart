import 'package:click_campus_parent/views/messages/messages_main.dart';
import 'package:flutter/material.dart';

import 'online_class_todays.dart';
import 'online_class_upcoming.dart';


class OnlineClassTabMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(
                text: "TODAY'S",
              ),
              Tab(text: "UPCOMING"),
            ],
          ),
          title: Text('Live Classes'),
        ),
        body: TabBarView(
          children: [
            OnineClassTodays(),
            OnlineClassUpcoming(),
          ],
        ),
      ),
    );
  }
}
