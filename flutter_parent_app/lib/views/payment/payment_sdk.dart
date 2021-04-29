library atompaynetz;

import 'dart:convert';

import 'package:crypto/crypto.dart';

class AtomPaynetz {
  final String login;
  final String pass;
  final String ttype = "NBFundTransfer";
  final String prodid;
  final String amt;
  final String txnid;
  final String txncurr = "INR";
  final String txnscamt = "0";
  final String clientcode = "NAVIN";
  final String date;
  final String custacc;
  final String responsehashKey;
  final String responseencypritonKey;
  final String responsesaltKey;
  final String requesthashKey;
  final String requestencryptionKey;
  final String requestsaltKey;
  final String mode;
  final String platform;

  final String udf1;
  final String udf2;
  final String udf3;
  final String udf4;

  AtomPaynetz({this.login,
    this.pass,
    this.prodid,
    this.amt,
    this.date,
    this.txnid,
    this.custacc,
    this.requesthashKey,
    this.requestencryptionKey,
    this.requestsaltKey,
    this.responsehashKey,
    this.responseencypritonKey,
    this.responsesaltKey,
    this.mode,
    this.udf1,
    this.udf2,
    this.udf3,
    this.udf4,
    this.platform});

  getUrl() {
    var signature = this.createSignature();
    var bytes = utf8.encode(this.clientcode);
    var clientcodeEncoded = base64.encode(bytes);
    var url = "";
    if (this.mode == "live") {
      if (platform == "WITH_AES") {
        url = "https://www.atomtech.in/atomfluttersdk/AES/initiateAESPay.php?login=" +
            this.login +
            "&pass=" +
            this.pass +
            "&ttype=" +
            this.ttype +
            "&prodid=" +
            this.prodid +
            "&amt=" +
            this.amt +
            "&txncurr=" +
            this.txncurr +
            "&txnscamt=" +
            this.txnscamt +
            "&clientcode=" +
            clientcodeEncoded +
            "=&txnid=" +
            this.txnid +
            "&date=" +
            this.date +
            "&custacc=" +
            this.custacc +
            "&udf1=" +
            this.udf1 +
            "&udf2=" +
            this.udf2 +
            "&udf3=" +
            this.udf3 +
            "&udf4=" +
            this.udf4 +
            "&reqenckey=" +
            this.requestencryptionKey +
            "&reqencsaltkey=" +
            this.requestsaltKey +
            "&resenckey=" +
            this.responseencypritonKey +
            "&resencsaltkey=" +
            this.responsesaltKey +
            "&payurl=https://payment.atomtech.in/paynetz/epi/fts&ru=https://www.atomtech.in/atomfluttersdk/AES/index.php&signature=" +
            signature;
      } else {
        url = "https://payment.atomtech.in/paynetz/epi/fts?login=" +
            this.login +
            "&pass=" +
            this.pass +
            "&ttype=" +
            this.ttype +
            "&prodid=" +
            this.prodid +
            "&amt=" +
            this.amt +
            "&txncurr=" +
            this.txncurr +
            "&txnscamt=" +
            this.txnscamt +
            "&clientcode=" +
            clientcodeEncoded +
            "=&txnid=" +
            this.txnid +
            "&date=" +
            this.date +
            "&custacc=" +
            this.custacc +
            "&ru=https://www.atomtech.in/atomfluttersdk/index.php&signature=" +
            signature;
      }
    } else {
      if (platform == "WITH_AES") {
        url = "https://www.atomtech.in/atomfluttersdk/AES/initiateAESPay.php?login=" +
            this.login +
            "&pass=" +
            this.pass +
            "&ttype=" +
            this.ttype +
            "&prodid=" +
            this.prodid +
            "&amt=" +
            this.amt +
            "&txncurr=" +
            this.txncurr +
            "&txnscamt=" +
            this.txnscamt +
            "&clientcode=" +
            clientcodeEncoded +
            "=&txnid=" +
            this.txnid +
            "&date=" +
            this.date +
            "&custacc=" +
            this.custacc +
            "&udf1=" +
            this.udf1 +
            "&udf2=" +
            this.udf2 +
            "&udf3=" +
            this.udf3 +
            "&udf4=" +
            this.udf4 +
            "&reqenckey=" +
            this.requestencryptionKey +
            "&reqencsaltkey=" +
            this.requestsaltKey +
            "&resenckey=" +
            this.responseencypritonKey +
            "&resencsaltkey=" +
            this.responsesaltKey +
            "&payurl=https://paynetzuat.atomtech.in/paynetz/epi/fts&ru=https://www.atomtech.in/atomfluttersdk/AES/index.php&signature=" +
            signature;
      } else {
        url = "https://paynetzuat.atomtech.in/paynetz/epi/fts?login=" +
            this.login +
            "&pass=" +
            this.pass +
            "&ttype=" +
            this.ttype +
            "&prodid=" +
            this.prodid +
            "&amt=" +
            this.amt +
            "&txncurr=" +
            this.txncurr +
            "&txnscamt=" +
            this.txnscamt +
            "&clientcode=" +
            clientcodeEncoded +
            "=&txnid=" +
            this.txnid +
            "&date=" +
            this.date +
            "&custacc=" +
            this.custacc +
            "&ru=https://www.atomtech.in/atomfluttersdk/index.php&signature=" +
            signature;
      }

    }
    return (url);
  }

  createSignature() {
    String signatureString = this.login +
        this.pass +
        this.ttype +
        this.prodid +
        this.txnid +
        this.amt +
        this.txncurr;
    var bytes = utf8.encode(signatureString);
    var key = utf8.encode(this.requesthashKey);
    var hmacSha512 = new Hmac(sha512, key); // HMAC-SHA256
    var digest = hmacSha512.convert(bytes);
    return (digest.toString());
  }

  validateSignature({mmp_txn,
    mer_txn,
    f_code,
    prod,
    discriminator,
    amt,
    bank_txn,
    signature}) {
    String signatureString =
        mmp_txn + mer_txn + f_code + prod + discriminator + amt + bank_txn;
    var bytes = utf8.encode(signatureString);
    var key = utf8.encode(this.responsehashKey);
    var hmacSha512 = new Hmac(sha512, key); // HMAC-SHA256
    var digest = hmacSha512.convert(bytes);
    var genSig = digest.toString();
    if (signature == genSig) {
      return true;
    } else {
      return false;
    }
  }
}
