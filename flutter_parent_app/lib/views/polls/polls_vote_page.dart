import 'package:flutter/material.dart';

class PollsVotePage extends StatefulWidget {
  @override
  State createState() => StatePollsVotePage();
}

class StatePollsVotePage extends State<PollsVotePage> {
  int selectedItem = -1;

  Widget getGridItem(bool isSelected) {
    if (1 == 1) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Flexible(
                    child: Image.asset(
                  "assets/main_back.jpg",
                  width: double.infinity,
                  fit: BoxFit.cover,
                )),
                Center(
                  child: Text("Prateek Sharma"),
                  heightFactor: 2,
                )
              ],
            ),
            (isSelected)
                ? Container(
                    color: Colors.black45,
                    child: Center(
                      child: Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  )
                : Container()
          ],
        ),
      );
    } else {
      return Card(
        child: Center(
          child: Text("Ashish Walia Walia"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
                      Divider(),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "Please select an option from the following",
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ),
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1,
                      crossAxisCount: 2),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return GestureDetector(
                        child: getGridItem((selectedItem == index)),
                        onTap: () {
                          setState(() {
                            selectedItem = index;
                          });
                        },
                      );
                    },
                    childCount: 4,
                  ),
                ),
              ],
            ),
          ),
          Align(
            child: Container(
              color: Colors.indigo,
              child: FlatButton(
                  onPressed: null,
                  child: Text(
                    "SUBMIT",
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
