import 'package:click_campus_parent/views/polls/polls_vote_page.dart';
import 'package:flutter/material.dart';

class PollsNewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StatePollsNewPage();
  }
}

class StatePollsNewPage extends State<PollsNewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: EdgeInsets.all(8),
        separatorBuilder: (context, position) {
          return Divider();
        },
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Who is your favorite head boy'),
            trailing: Image.asset(
              "assets/main_back.jpg",
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext context) {
                return PollsVotePage();
              }));
            },
          );
        },
        itemCount: 10,
      ),
    );
  }
}
