import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();

  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "TestDB.db");
    return await openDatabase(path, version: 1, onOpen: (db) {},
        onCreate: (Database db, int version) async {
      await db.execute("create table app_users " +
          "( " +
          " login_id integer " +
          " primary key, " +
          " mobile_no text not null, " +
          " active_session text not null, " +
          " login_record_id integer " +
          ");");

      await db.execute("create table master_school_info " +
          "( " +
          "affiliation_no TEXT not null, " +
          "school_code TEXT not null, " +
          "school_name TEXT not null, " +
          "school_short_name text null, " +
          "address TEXT not null, " +
          "country_id INTEGER not null, " +
          "state_id INTEGER not null, " +
          "city_id INTEGER not null, " +
          "contact_no TEXT not null, " +
          "weblink text null, " +
          "facebook_link text not null, " +
          "email TEXT null, " +
          "logo_path TEXT null, " +
          "board_logo_path TEXT null, " +
          "school_banner text not null, " +
          "print_fee_option BOOLEAN, " +
          "show_concession BOOLEAN, " +
          "date_format text, " +
          "sr_format TEXT not null " +
          ");");

      await db.execute("create table sessions " +
          "( " +
          "session_id int not null, " +
          "session_name text not null, " +
          "default_session int not null, " +
          "active_session int not null default 0 " +
          "); ");

      await db.execute("create table messages " +
          "( " +
          "message_id int not null, " +
          "message_text text not null, " +
          "message_media_type text not null, " +
          "sender_name text not null, " +
          "sender_image text, " +
          "date text not null, " +
          "file text not null, " +
          "file_media_type text not null " +
          "); ");
    });
  }
}
