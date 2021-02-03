import 'package:flutter/material.dart';

class PollDetails extends StatefulWidget {
  @override
  State createState() => StatePollDetails();
}

class StatePollDetails extends State<PollDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Polls Result"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Column(
                    children: <Widget>[
                      Align(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            "Who would like to be your head boud ? ",
                            style: TextStyle(
                              fontSize: 22,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        alignment: Alignment.center,
                      ),
                      Align(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Image.asset(
                            "assets/main_back.jpg",
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        alignment: Alignment.center,
                      ),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ),
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                  return ListTile(
                    title: Text(
                      "Option 1",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    subtitle: RichText(
                        text: TextSpan(
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            children: [
                          TextSpan(
                            text: "Votes Receieved : ",
                          ),
                          TextSpan(
                            text: "\n80% Votes(45/50)",
                            style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.normal),
                          ),
                        ])),
                    trailing: Image.asset(
                      "assets/main_back.jpg",
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                    ),
                  );
                }, childCount: 2))
              ],
            ),
          ),
          Align(
            child: Container(
              color: Colors.indigo,
              child: FlatButton(
                  onPressed: null,
                  child: Text(
                    "PUBLISH",
                    style: TextStyle(color: Colors.white),
                  )),
              width: double.infinity,
            ),
            alignment: Alignment.bottomCenter,
          )
        ],
      ),
    );
  }
}
