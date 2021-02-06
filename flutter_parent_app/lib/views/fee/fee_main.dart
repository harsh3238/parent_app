import 'dart:convert';
import 'dart:developer';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/views/payment/payment_gateway_screen.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class FeeMain extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FeeMainState();
  }
}

class _FeeMainState extends State<FeeMain> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  bool _didGetData = false;
  int activeTab = 0;
  var today = DateFormat().addPattern("dd, MMM yyyy").format(DateTime.now());
  List<dynamic> _duesData = [];
  List<dynamic> _feesData = [];
  List<dynamic> _paymentList = [];
  bool isNoData = false;
  bool showTotal = false;
  String feesDue = "Not Available";
  int grandTotal = 0;

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!_didGetData) {
      _didGetData = true;
      Future.delayed(Duration(milliseconds: 100), () async {
        _getFeesData();
      });
    }

    return Scaffold(
      key: _scaffoldState,
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Due Fees"),
      ),
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
                                  Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Container(
                                      height: 25,
                                      width:
                                          (MediaQuery.of(context).size.width /
                                                  2) -
                                              15,
                                      child: FlatButton(
                                        onPressed: () {
                                          setState(() {
                                            activeTab = 0;
                                            showTotal = false;
                                            _feesData.clear();
                                            isNoData = false;
                                            _getFeesData();
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
                                  Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Container(
                                      height: 25,
                                      width:
                                          (MediaQuery.of(context).size.width /
                                                  2) -
                                              15,
                                      child: FlatButton(
                                        onPressed: () {
                                          setState(() {
                                            activeTab = 1;
                                            _duesData.clear();
                                            isNoData = false;
                                            _getDuesData();
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
                                            text: today.toString(),
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
                            /* Text("Due Fee",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),*/
                            Text("₹ " + feesDue,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 32)),
                            Text("Due Fee",
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
              delegate: SliverChildListDelegate([
            SingleChildScrollView(
              child: activeTab == 0 ? _buildFeesList() : _buildDuesList(),
            )
          ])),
          SliverList(
              delegate: SliverChildListDelegate([
            SingleChildScrollView(
              child:
                  activeTab == 1 && showTotal ? _getTotalAmount() : Container(),
            )
          ]))
        ],
      )),
    );
  }

  void addPaymentData(int position){
    debugPrint("POSITION:"+position.toString());
    _paymentList.clear();
    grandTotal = 0;
    for(int i=0; i<=position; i++){
      _paymentList.add(_duesData[i]);
      grandTotal = grandTotal + _duesData[i]['amount'];
      debugPrint("Item Added");
    }
    setState(() { });

  }

  Widget _getTotalAmount() {
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: Colors.blue,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Payment Details",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          _buildDuesSubList(),
          Divider(
              color: Colors.black
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(8),
                child: Container(
                  height: 25,
                  child: Text("Grand Total", style: TextStyle(fontWeight: FontWeight.bold),),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Container(
                  height: 25,
                  child: Text(grandTotal.toString(), style: TextStyle(fontWeight: FontWeight.bold),),
                ),
              ),
              SizedBox(width: 5,)
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 35.0,
              width: 150,
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius:
                BorderRadius.circular(30.0),
                child: Container(
                  width: 150,
                  height: 10.0,
                  color: Colors.blue,
                  child: GestureDetector(
                    onTap: (){
                      StateHelper().showShortToast(context, "This feature will be roll out soon");
                      //navigateToModule(PaymentGatewayScreen("Fee Dues Payment", grandTotal.toString(), "", ""));
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new Text("Make Payment",
                            style: TextStyle(
                              color: Colors.white,
                            )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDuesList() {
    return Container(
        child: _duesData.length > 0
            ? ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _duesData.length,
                itemBuilder: (BuildContext context, int index) {
                  Map mode = _duesData[index]["fee_mode"];
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Text(mode['fee_mode_name'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                      fontSize: 12)),
                              Text(mode['due_date'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 12))
                            ],
                            crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                          Spacer(),
                          Container(
                            height: 20,
                            child: FlatButton(
                              onPressed: () {
                                setState(() {
                                  addPaymentData(index);
                                  showTotal = true;
                                });
                              },
                              color: Colors.orange,
                              child: Text(
                                "Pay Now",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(40)),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            children: <Widget>[
                              Text("₹ " + _duesData[index]['amount'].toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      fontSize: 12)),
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
                })
            : Container(
                height: 200,
                child: Center(
                    child: isNoData
                        ? Text("No Data Available")
                        : CircularProgressIndicator())));
  }


  Widget _buildDuesSubList() {
    return Container(
      color: Colors.white,
        child: _paymentList.length > 0
            ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _paymentList.length,
            itemBuilder: (BuildContext context, int index) {
              Map mode = _paymentList[index]["fee_mode"];
              return Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(mode['fee_mode_name'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                fontSize: 12)),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Column(
                      children: <Widget>[
                        Text("₹ " + _paymentList[index]['amount'].toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 12)),
                      ],
                      crossAxisAlignment: CrossAxisAlignment.end,
                    )
                  ],
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              );
            })
            : Container(
            height: 200,
            child: Center(
                child: isNoData
                    ? Text("No Data Available")
                    : CircularProgressIndicator())));
  }

  Widget _buildFeesList() {
    return Container(
        child: _feesData.length > 0
            ? ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _feesData.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {},
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                          "Receipt No. :" +
                                              _feesData[index]['rec_no_label']
                                                  .toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 12)),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Visibility(
                                        visible: _feesData[index]
                                                    ['cancel_reason'] ==
                                                null
                                            ? false
                                            : true,
                                        child: Container(
                                          height: 18.0,
                                          width: 80,
                                          color: Colors.transparent,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(30.0),
                                            child: Container(
                                              width: 40,
                                              height: 10.0,
                                              color: Colors.red,
                                              child: Center(
                                                child: new Text("Cancelled",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    )),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(_feesData[index]['mode'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                          fontSize: 12)),
                                  Text(_feesData[index]['paying_date'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          fontSize: 12)),
                                  Visibility(
                                    visible:
                                        _feesData[index]['cancel_status'] == 0
                                            ? false
                                            : true,
                                    child: Text(
                                        _feesData[index]['cancel_reason'] !=
                                                null
                                            ? "Reason: " +
                                                _feesData[index]
                                                    ['cancel_reason']
                                            : "Reason not available",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                            fontSize: 12)),
                                  )
                                ],
                                crossAxisAlignment: CrossAxisAlignment.start,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: <Widget>[
                                  _feesData[index]['cancel_status'] == 1
                                      ? Text(
                                          "₹ " + _feesData[index]['paid_amt'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.lineThrough))
                                      : Text(
                                          "₹ " + _feesData[index]['paid_amt'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                              fontSize: 12)),
                                  Text(_feesData[index]['receipt_type'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          fontSize: 12)),
                                ],
                                crossAxisAlignment: CrossAxisAlignment.end,
                              ),
                            )
                          ],
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        ),
                      ),
                      elevation: 0,
                    ),
                  );
                })
            : Container(
                height: 200,
                child: Center(
                    child: isNoData
                        ? Text("No Data Available")
                        : CircularProgressIndicator())));
  }

  void _getFeesData() async {
    String sessionToken = await AppData().getSessionToken();
    int studentId = await AppData().getSelectedStudent();
    var requestBody = {
      'session_id': "3",
      'stucare_id': studentId.toString(),
      'active_session': sessionToken,
    };

    debugPrint("${requestBody}");

    var modulesResponse =
        await http.post(GConstants.getFeeDataRoute(), body: requestBody);

    log("${modulesResponse.request} : ${modulesResponse.body}");

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("success")) {
        if (modulesResponseObject["success"] == true) {
          feesDue = modulesResponseObject["feedue"].toString();
          _feesData = modulesResponseObject['data'];

          if (_feesData != null && _feesData.length > 0) {
            isNoData = false;
          } else {
            _feesData = [];
            isNoData = true;
            StateHelper().showShortToast(context, "No Data Available");
          }
          setState(() {});
          return null;
        } else {
          isNoData = true;
          setState(() {});
          showSnackBar(modulesResponseObject["message"]);
          return null;
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
    }
  }

  void _getDuesData() async {
    String sessionToken = await AppData().getSessionToken();
    int studentId = await AppData().getSelectedStudent();

    var requestBody = {
      'session_id': "3",
      'stucare_id': studentId.toString(),
      'active_session': sessionToken,
    };
    var modulesResponse =
        await http.post(GConstants.getDuesDataRoute(), body: requestBody);

    debugPrint("${modulesResponse.request} ; ${modulesResponse.body}");

    if (modulesResponse.statusCode == 200) {
      Map modulesResponseObject = json.decode(modulesResponse.body);
      if (modulesResponseObject.containsKey("success")) {
        if (modulesResponseObject["success"] == true) {
          _duesData = modulesResponseObject['data'];
          if (_duesData != null && _duesData.length > 0) {
            isNoData = false;
          } else {
            _duesData = [];
            isNoData = true;
            StateHelper().showShortToast(context, "No Data Available");
          }
          setState(() {});
          return null;
        } else {
          isNoData = true;
          setState(() {});
          showSnackBar(modulesResponseObject["message"]);
          return null;
        }
      } else {
        showServerError();
      }
    } else {
      showServerError();
    }
  }

  void navigateToModule(Widget module) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => module),
    );
  }
}
