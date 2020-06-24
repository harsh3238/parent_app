import 'package:flutter/material.dart';

class TimetableMain extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TimetableMainState();
  }
}

class _TimetableMainState extends State<TimetableMain> {
  var deviceSize;

  var data = new Map();

  void createData() {
    data["Maths"] = "Mr. Murari Lal";
    data["English"] = "Mr. Murari Lal";
    data["Hindi"] = "Mr. Murari Lal";
    data["SST"] = "Mr. Murari Lal";
    data["Computer/Sports"] = "Mr. Murari Lal/Ram Mohan Sharma";
    data["Physics"] = "Mr. Murari Lal";
    data["Chemistry"] = "Mr. Murari Lal";
    data["Biology"] = "Mr. Murari Lal";
  }

  Widget tabColumn(Size deviceSize) => Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      "MON",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  splashColor: Colors.white,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      "TUE",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  splashColor: Colors.white,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      "WED",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  splashColor: Colors.white,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      "THE",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  splashColor: Colors.white,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      "FRI",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  splashColor: Colors.white,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Text(
                      "SAT",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  splashColor: Colors.white,
                ),
              )
            ],
          ),
          color: Colors.blue,
        ),
      );

  Widget theClassInfoTable() => Padding(
        padding: EdgeInsets.all(20),
        child: Table(
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
          },
          children: getTableItems(),
        ),
      );

  List<TableRow> getTableItems() {
    List<TableRow> tablesRows = List();
    /*data.keys.forEach((key) {
      tablesRows.add(_buildItemRow(data[key], "okay"));
    });*/
    tablesRows.add(_buildItemRow(0, "Subject", "Teacher"));
    for (int i = 0; i < data.keys.length; i++) {
      tablesRows.add(_buildItemRow(
          i + 1, data.keys.elementAt(i), data[data.keys.elementAt(i)]));
    }
    return tablesRows;
  }

  TableRow _buildItemRow(int index, String subjectName, String teacherName) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            (index == 0) ? "Period" : index.toString(),
            style: (index == 0)
                ? TextStyle(fontWeight: FontWeight.bold,)
                : TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            subjectName,
            style: (index == 0)
                ? TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                : TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            teacherName,
            style: (index == 0)
                ? TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                : TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceSize = MediaQuery.of(context).size;
    createData();
    return Scaffold(
      appBar: AppBar(
        title: Text("Timetable"),
      ),
      body: Column(
        children: <Widget>[tabColumn(deviceSize), theClassInfoTable()],
      ),
    );
  }
}
