import 'dart:convert';
import 'dart:developer';

import 'package:click_campus_parent/config/g_constants.dart';
import 'package:click_campus_parent/data/app_data.dart';
import 'package:click_campus_parent/views/state_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ViewRemark extends StatefulWidget {

  String name, studentClass, description, remarkType, teacher;
  int remarkVisibility, remarkCategory;
  Map remarkData;

  ViewRemark(this.name, this.studentClass, this.description,
      this.remarkType, this.remarkVisibility, this.remarkCategory, this.teacher);

  @override
  State<StatefulWidget> createState() {
    return StateViewRemark();
  }
}

class StateViewRemark extends State<ViewRemark> with StateHelper {
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _descriptionTextController = TextEditingController();

  bool _firstRunRoutineRan = false;

  FocusNode descriptionFocus = FocusNode();

  List<dynamic> _classList = [];
  Map<String, dynamic> _selectedClass;

  List<dynamic> _sectionsList = [];
  Map<String, dynamic> _selectedSection;

  List<dynamic> _studentList = [];
  Map<String, dynamic> _selectedStudent;

  List<dynamic> _remarkTypeList = [];
  Map<String, dynamic> _selectedRemarkType;

  String mSelectedDate = DateFormat().addPattern("dd-MM-yyyy").format(DateTime.now());
  TimeOfDay mSelectedTime = TimeOfDay.now();

  List<DropdownMenuItem<Map<String, dynamic>>> getSelectableClasses() {
    return _classList.map((item) {
      return DropdownMenuItem<Map<String, dynamic>>(
        child: Text(item['class_name']),
        value: item,
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    super.init(context, _scaffoldState, state: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstRunRoutineRan) {
      _firstRunRoutineRan = true;
      Future.delayed(Duration(milliseconds: 100), () async {
      });
    }

    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        title: Text("Remark Details"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
              child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[

                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 15, 10, 0),
                      child: Container(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0), color: Colors.white54, border: Border.all()),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<dynamic>(
                            iconEnabledColor: Colors.white,
                            iconDisabledColor: Colors.white,
                            items: _studentList
                                .map((b) => DropdownMenuItem<dynamic>(
                              child: Text(
                                b['student_name'],
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              value: b,
                            ))
                                .toList(),
                            onChanged: (b) {
                              if (b == _selectedStudent) {
                                return;
                              }

                              setState(() {
                                _selectedStudent = b;
                              });
                            },
                            hint: Text(
                            "Name: "+widget.name,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            isExpanded: true,
                            value: _selectedStudent,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 15, 10, 0),
                      child: Container(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0), color: Colors.white54, border: Border.all()),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<dynamic>(
                            iconEnabledColor: Colors.white,
                            iconDisabledColor: Colors.white,
                            items: _classList
                                .map((b) => DropdownMenuItem<dynamic>(
                                      child: Text(
                                        b['class_name'],
                                        style: TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      value: b,
                                    ))
                                .toList(),
                            onChanged: (b) {

                            },
                            hint: Text(
                              "Class: "+widget.studentClass,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            isExpanded: true,
                            value: _selectedClass,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 15, 10, 0),
                      child: Container(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0), color: Colors.white54, border: Border.all()),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<dynamic>(
                            iconEnabledColor: Colors.white,
                            iconDisabledColor: Colors.white,
                            items: _remarkTypeList
                                .map((b) => DropdownMenuItem<dynamic>(
                              child: Text(
                                b['remark'],
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              value: b,
                            ))
                                .toList(),
                            onChanged: (b) {
                              if (b == _selectedRemarkType) {
                                return;
                              }

                              setState(() {
                                _selectedRemarkType = b;
                              });
                            },
                            hint: Text(
                              "Type: "+widget.remarkType,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            isExpanded: true,
                            value: _selectedRemarkType,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 15, 10, 0),
                      child: Container(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0), color: Colors.white54, border: Border.all()),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<dynamic>(
                            iconEnabledColor: Colors.white,
                            iconDisabledColor: Colors.white,
                            items: _remarkTypeList
                                .map((b) => DropdownMenuItem<dynamic>(
                              child: Text(
                                b['remark'],
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              value: b,
                            ))
                                .toList(),
                            onChanged: (b) {
                              if (b == _selectedRemarkType) {
                                return;
                              }

                              setState(() {
                                _selectedRemarkType = b;
                              });
                            },
                            hint: Text(
                              "Teacher: "+widget.teacher,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            isExpanded: true,
                            value: _selectedRemarkType,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 18.0, bottom: 0),
                      child: Text(
                        "Remark Description",
                        style: TextStyle(fontSize: 17, color: Colors.black38, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                        child: TextFormField(
                          focusNode: descriptionFocus,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: widget.description,
                            contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 2),
                          ),
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.text,
                          scrollPadding: EdgeInsets.all(0),
                          style: TextStyle(color: Colors.grey),
                          controller: _descriptionTextController,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 18.0, bottom: 0),
                      child: Text(
                        "Remark Visibility",
                        style: TextStyle(fontSize: 17, color: Colors.black38, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _getActionButtons(),
                    Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0, bottom: 0),
                      child: Text(
                        "Category of Remark",
                        style: TextStyle(fontSize: 17, color: Colors.black38, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 20.0, right: 12.0, top: 12.0, bottom: 15),
                      child: Row(
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              widget.remarkCategory==1?Icons.thumb_down:Icons.thumb_down_alt_outlined,
                              size: 40,
                              color: Colors.red,
                            ),
                            highlightColor: Colors.grey,
                            onPressed: (){
                            },
                          ),
                          SizedBox(width: 30),
                          IconButton(
                            icon: Icon(
                              widget.remarkCategory==2?Icons.thumb_up:Icons.thumb_up_alt_outlined,
                              size: 40,
                              color: Colors.green,
                            ),
                            highlightColor: Colors.grey,
                            onPressed: (){
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),],
      ),
    );
  }

  Widget _getActionButtons() {
    return Padding(
      padding: EdgeInsets.only(left: 12.0, right: 12.0, top: 15.0, bottom: 15),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Container(
                  height: 45,
                  child: new RaisedButton(
                    child: new Text("Parent"),
                    textColor: Colors.white,
                    color: widget.remarkVisibility==1?Colors.deepOrange:Colors.black26,
                    onPressed: () async {
                    },
                    shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
                  )),
            ),
            flex: 2,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Container(
                  height: 45,
                  child: new RaisedButton(
                    child: new Text("School"),
                    textColor: Colors.white,
                    color: widget.remarkVisibility==2?Colors.deepOrange:Colors.black26,
                    onPressed: () {
                    },
                    shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0)),
                  )),
            ),
            flex: 2,
          ),
        ],
      ),
    );
  }

}
