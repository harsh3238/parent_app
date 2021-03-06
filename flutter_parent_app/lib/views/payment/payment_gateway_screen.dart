import 'dart:convert';
import 'dart:core';
import 'dart:developer';

import 'package:atompaynetz/atompaynetz.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:intl/intl.dart';

class PaymentGatewayScreen extends StatefulWidget {
  String title;
  String price;
  String productId;
  String orderId;
  String transactionId;

  PaymentGatewayScreen(this.title, this.price, this.productId, this.orderId);

  @override
  State<StatefulWidget> createState() {
    return PaymentGatewayScreenState();
  }
}

class PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  final flutterWebViewPlugin = FlutterWebviewPlugin();

  @override
  void initState() {
    super.initState();

    flutterWebViewPlugin.onUrlChanged.listen((String url) {
      log(url, name: "RESPONSE");
      if (url.contains('/response.php')) {
        var pageUrl = url.substring(0, url.indexOf('?'));
        var subString = url.substring(url.indexOf("?") + 1, url.length);
        log(pageUrl, name: "URL");
        log(subString, name: "SUB_STRING");
        Map transactionInfo = splitQueryString(subString);
        log(transactionInfo.toString(), name: "TRANSACTION");

        widget.transactionId = transactionInfo["mer_txn"];

        var urlarray = url
            .split('&')
            .map((String val) => {
                  if (val.contains("f_code"))
                    {
                      if (val == "f_code=Ok")
                        {StateHelper().showShortToast(context, "Payment Success")}
                      else if (val == "f_code=F")
                        {StateHelper().showShortToast(context, "Payment Failed")}
                      else if (val == "f_code=C")
                        {StateHelper().showShortToast(context, "Payment Canceled")}
                    }
                })
            .toList();
        log("ARRAY: ${urlarray}");
        flutterWebViewPlugin.close();
        //Navigator.of(context).pop();
        Navigator.pop(context, transactionInfo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getUrl(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
              key: _scaffoldState,
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: Container(
                child: WebviewScaffold(
                  url: snapshot.data,
                ),
              ));
        } else {
          return Container(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future<String> getUrl() async {


    DateTime now = DateTime.now();
    final customDateFormat = new DateFormat('dd/MM/yyyy HH:mm:ss');
    var mDate = customDateFormat.format(now);

    var atompay = new AtomPaynetz(
        login: '9132',
        pass: 'Test@123',
        prodid: 'NSE',
        amt: widget.price,
        date: mDate.toString(),
        txnid: widget.orderId !=""?widget.orderId:DateTime.now().millisecondsSinceEpoch.toString(),
        custacc: '0',
        udf1: 'Stucare Student',
        udf2: 'stucare@gmail.com',
        udf3: '9999999999',
        udf4: 'Noida',
        requesthashKey: 'KEY123657234',
        requestencryptionKey: 'A4476C2062FFA58980DC8F79EB6A799E',
        requestsaltKey: 'A4476C2062FFA58980DC8F79EB6A799E',
        responsehashKey: 'KEYRESP123657234',
        responseencypritonKey: '75AEF0FA1B94B3C10D4F5B268F757F11',
        responsesaltKey: '75AEF0FA1B94B3C10D4F5B268F757F11',
        mode: 'uat'); // put mode: 'live' in production

    var urlToSend = atompay.getUrl();
    debugPrint("URL GENERATED: ${urlToSend}");
    return urlToSend;
  }


  static Map<String, String> splitQueryString(String query,
      {Encoding encoding = utf8}) {
    return query.split("&").fold({}, (map, element) {
      int index = element.indexOf("=");
      if (index == -1) {
        if (element != "") {
          map[Uri.decodeQueryComponent(element, encoding: encoding)] = "";
        }
      } else if (index != 0) {
        var key = element.substring(0, index);
        var value = element.substring(index + 1);
        map[Uri.decodeQueryComponent(key, encoding: encoding)] =
            Uri.decodeQueryComponent(value, encoding: encoding);
      }
      return map;
    });
  }
}
