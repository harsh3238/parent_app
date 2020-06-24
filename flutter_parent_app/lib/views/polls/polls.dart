import 'package:click_campus_parent/views/polls/polls_new_page.dart';
import 'package:click_campus_parent/views/polls/previous_polls.dart';
import 'package:flutter/material.dart';

class PollsMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(
                text: "New Polls",
              ),
              Tab(text: "Previous Polls"),
            ],
          ),
          title: Text('Polls'),
        ),
        body: TabBarView(
          children: [
            PollsNewPage(),
            PreviousPollsPage()
          ],
        ),
      ),
    );
  }
}
