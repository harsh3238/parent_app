import 'package:click_campus_parent/data/db_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class AppData {
  static final AppData _singleton = new AppData._internal();
  static const String TABLE_NAME = "app_users";
  Database _db;
  SharedPreferences _prefs;

  factory AppData() {
    return _singleton;
  }

  AppData._internal();

  Future<void> _init() async {
    if (_db != null) {
      return;
    }
    _db = await DBProvider.db.database;
  }

  Future<Database> getDb() async {
    await _init();
    return _db;
  }

  Future<void> getPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<int> getSelectedStudent() async {
    await getPrefs();
    return _prefs.getInt("selected_stucare_id") ?? null;
  }

  Future<void> setSelectedStudent(int stucareId) async {
    await getPrefs();
    _prefs.setInt("selected_stucare_id", stucareId);
    return null;
  }

  Future<String> getSelectedStudentName() async {
    await getPrefs();
    return _prefs.getString("selected_student_name") ?? null;
  }

  Future<void> setSelectedStudentName(String studentName) async {
    await getPrefs();
    _prefs.setString("selected_student_name", studentName);
    return null;
  }

  Future<bool> areWeLoggedIn() async {
    int users = await getUserCount();
    if (users > 0) {
      return true;
    }
    return false;
  }

  Future<int> getUserCount() async {
    await _init();
    var rs = await _db.rawQuery("SELECT COUNT(login_id) FROM $TABLE_NAME;");
    int count = rs[0]["COUNT(login_id)"];
    return count;
  }

  Future<int> getUserLoginId() async {
    await _init();
    var rs = await _db.rawQuery("SELECT login_id FROM $TABLE_NAME;");
    if (rs.length > 0) {
      int loginId = rs[0]["login_id"];
      return loginId;
    }
    return 0;
  }

  Future<String> getSessionToken() async {
    await _init();
    var rs = await _db.rawQuery("SELECT active_session FROM $TABLE_NAME;");
    if (rs.length > 0) {
      String sessionToken = rs[0]["active_session"];
      return sessionToken;
    }
    return null;
  }

  Future<bool> deleteAllUsers() async {
    await _init();
    var rs = await _db.rawDelete("DELETE FROM $TABLE_NAME;");
    if (rs > 0) {
      return true;
    }
    return false;
  }

  Future<void> saveUsersData(Map<String, dynamic> usersData) async {
    await _init();
    var batch = _db.batch();
    batch.delete(TABLE_NAME);
    batch.insert(TABLE_NAME, usersData);
    await batch.commit(noResult: true);
    //print("INSERTED USERS DATA");
  }

  Future<void> setImpersonatedSchoolId(String schoolId) async {
    await getPrefs();
    _prefs.setString("impersonated_school", schoolId);
    return null;
  }

  Future<String> getImpersonatedSchool() async {
    await getPrefs();
    return _prefs.getString("impersonated_school") ?? null;
  }

  Future<void> setNormalSchoolRootUrlAndId(
      String schoolRoot, String schoolId) async {
    await getPrefs();
    _prefs.setString("normal_login_school_id", schoolId);
    _prefs.setString("normal_login_school_url", schoolRoot);
    return null;
  }

  Future<String> getNormalSchoolId() async {
    await getPrefs();
    return _prefs.getString("normal_login_school_id") ?? null;
  }

  Future<String> getNormalSchoolUrl() async {
    await getPrefs();
    return _prefs.getString("normal_login_school_url") ?? null;
  }

  Future<void> setStucareEmpId(String stucareEmpId) async {
    await getPrefs();
    _prefs.setString("stucare_emp_id", stucareEmpId);
    return null;
  }

  Future<String> getStucareEmpId() async {
    await getPrefs();
    return _prefs.getString("stucare_emp_id") ?? null;
  }

  Future<String> getLoggedInUsersPhone() async {
    await _init();
    var rs = await _db.rawQuery("SELECT mobile_no FROM $TABLE_NAME;");
    if (rs.length > 0) {
      String mobile = rs[0]["mobile_no"];
      return mobile;
    }
    return null;
  }

  Future<void> setLastMessageId(int msgId) async {
    await getPrefs();
    _prefs.setInt("last_msg_id", msgId);
    return null;
  }

  Future<int> getLastMessageId() async {
    await getPrefs();
    return _prefs.getInt("last_msg_id") ?? null;
  }

  Future<void> setHomeworkSeen(String time) async {
    await getPrefs();
    _prefs.setString(
        "hoework_today", time??DateTime.now().toIso8601String());
    _prefs.setString(
        "hoework_yesturday", time?? DateTime.now().toIso8601String());
    return null;
  }

  Future<String> getHomeworkSeen(String type) async {
    await getPrefs();
    if (type == "todays") {
      return _prefs.getString("hoework_today");
    }
    return _prefs.getString("hoework_yesturday");
  }


  Future<String> getSelectedStudentClass() async {
    await getPrefs();
    return _prefs.getString("selected_student_class") ?? null;
  }

  Future<void> setSelectedStudentClass(String classId) async {
    await getPrefs();
    _prefs.setString("selected_student_class", classId);
    return null;
  }

  Future<String> getAccessKey() async {
    await getPrefs();
    return _prefs.getString("access_key") ?? null;
  }

  Future<void> setAccessKey(String accessKey) async {
    await getPrefs();
    _prefs.setString("access_key", accessKey);
    return null;
  }

  Future<String> getSecretKey() async {
    await getPrefs();
    return _prefs.getString("secret_key") ?? null;
  }

  Future<void> setSecretKey(String accessKey) async {
    await getPrefs();
    _prefs.setString("secret_key", accessKey);
    return null;
  }

  Future<String> getBucketName() async {
    await getPrefs();
    return _prefs.getString("aws_bucket_name") ?? null;
  }

  Future<void> setBucketName(String bucketName) async {
    await getPrefs();
    _prefs.setString("aws_bucket_name", bucketName);
    return null;
  }

  Future<String> getBucketRegion() async {
    await getPrefs();
    return _prefs.getString("aws_bucket_region") ?? null;
  }

  Future<void> setBucketRegion(String region) async {
    await getPrefs();
    _prefs.setString("aws_bucket_region", region);
    return null;
  }

  Future<String> getBucketUrl() async {
    await getPrefs();
    return _prefs.getString("aws_bucket_url") ?? null;
  }

  Future<void> setBucketUrl(String url) async {
    await getPrefs();
    _prefs.setString("aws_bucket_url", url);
    return null;
  }

  Future<void> clearSharedPrefs() async {
    await getPrefs();
    await _prefs.clear();
    return null;
  }


}
