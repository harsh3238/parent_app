

import 'package:click_campus_parent/data/app_data.dart';
import 'package:sqflite/sqflite.dart';

class DbSchoolInfo {
  static final DbSchoolInfo _singleton = new DbSchoolInfo._internal();
  static const String _SCHOOL_INFO = "master_school_info";
  Database _db;

  factory DbSchoolInfo() {
    return _singleton;
  }

  DbSchoolInfo._internal();

  Future<void> _init() async {
    if (_db != null) {
      return;
    }
    _db = await AppData().getDb();
  }

  Future<String> insertSchoolInfo(Map<String, dynamic> data) async {
    //print("INSERTING SCHOOL INFO");
    await _init();
    var batch = _db.batch();
    batch.delete(_SCHOOL_INFO);

    data.remove('is_homework_moderated');
    data.remove('hindi_msg');
    data.remove('outer_msg');
    data.remove('print_gatepss');
    data.remove('app_version');
    batch.insert(_SCHOOL_INFO, data);

    await batch.commit(noResult: true);
    //print("INSERTED SCHOOL INFO");
    return null;
  }


  Future<String> getWebUrl() async {
    await _init();
    var rs = await _db.query(_SCHOOL_INFO, columns: ["weblink"]);
    return rs[0]['weblink'];
  }

  Future<String> getFacebookUrl() async {
    await _init();
    var rs = await _db.query(_SCHOOL_INFO, columns: ["facebook_link"]);
    return rs[0]['facebook_link'];
  }

  Future<String> getBannerUrl() async {
    await _init();
    var rs = await _db.query(_SCHOOL_INFO, columns: ["school_banner"]);
    return rs[0]['school_banner'];
  }

  Future<String> getEmail() async {
    await _init();
    var rs = await _db.query(_SCHOOL_INFO, columns: ["email"]);
    return rs[0]['email'];
  }

  Future<String> getPhone() async {
    await _init();
    var rs = await _db.query(_SCHOOL_INFO, columns: ["contact_no"]);
    return rs[0]['contact_no'];
  }

}
