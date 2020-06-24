import 'package:flutter/material.dart';

class PreviousPollsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StatePreviousPollsPage();
  }
}

class StatePreviousPollsPage extends State<PreviousPollsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: EdgeInsets.all(8),
        separatorBuilder: (context, position) {
          return Divider();
        },
        itemBuilder: (context, index) {
          return Column(
            children: <Widget>[
              Text(
                "Whos do you think would fit as your Head Boy?",
                style: TextStyle(color: Colors.grey.shade800),
              ),
              SizedBox(
                height: 10,
              ),
              Text("You Voted For",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(
                "Some Name",
                style: TextStyle(color: Colors.grey.shade800),
              )
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          );
        },
        itemCount: 10,
      ),
    );
  }
}
