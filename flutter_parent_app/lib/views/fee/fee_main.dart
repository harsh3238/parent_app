import 'package:flutter/material.dart';

class FeeMain extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FeeMainState();
  }
}

class _FeeMainState extends State<FeeMain> {
  int activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(title: Text("Due Fees"),),
      body: SafeArea(
          child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              child: Column(
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/color_back.jpg",
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            height: 20,
                          ),
                          Container(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Container(
                                        height: 25,
                                        child: FlatButton(
                                          onPressed: () {
                                            setState(() {
                                              activeTab = 0;
                                            });
                                          },
                                          color: (activeTab == 0)
                                              ? Colors.blue
                                              : Colors.white,
                                          child: Text(
                                            "Fees",
                                            style: TextStyle(
                                                color: (activeTab == 0)
                                                    ? Colors.white
                                                    : Colors.grey.shade700),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(40)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Container(
                                        height: 25,
                                        child: FlatButton(
                                          onPressed: () {
                                            setState(() {
                                              activeTab = 1;
                                            });
                                          },
                                          color: (activeTab == 1)
                                              ? Colors.blue
                                              : Colors.white,
                                          child: Text(
                                            "Dues",
                                            style: TextStyle(
                                                color: (activeTab == 1)
                                                    ? Colors.white
                                                    : Colors.grey.shade700),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(40)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      Positioned(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Material(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(40)),
                              child: Container(
                                height: 40,
                                decoration: new BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20))),
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Payment History ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.grey),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: '29 March, 2019',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        bottom: 40,
                      ),
                      Positioned(
                        top: 30,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text("Due Fee",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Container(
                              height: 20,
                            ),
                            Text("₹ 0",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18)),
                            Text("Inclusive of all taxes",
                                style: TextStyle(color: Colors.white))
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
              color: Colors.blue.shade50,
            ),
          ),
          SliverList(
              delegate:
                  SliverChildBuilderDelegate((BuildContext context, int index) {
            return Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text("Receipt No. : 2345",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 12)),
                        Text("Apr to May",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                fontSize: 12)),
                        Text("14-Jul-2018",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 12))
                      ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                    Column(
                      children: <Widget>[
                        Text("₹ 6000",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 12)),
                        Text("cash",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 12))
                      ],
                      crossAxisAlignment: CrossAxisAlignment.end,
                    )
                  ],
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              ),
              elevation: 0,
            );
          }, childCount: (activeTab == 0) ? 8 : 2))
        ],
      )),
    );
  }
}
