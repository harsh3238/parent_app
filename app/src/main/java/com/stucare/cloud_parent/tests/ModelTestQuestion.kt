package com.stucare.cloud_parent.tests

import java.io.Serializable

class ModelTestQuestion(val isReport: Boolean) : Serializable {


  var questionId = ""
  var question = ""
  var optionA = ""
  var optionB = ""
  var optionC = ""
  var optionD = ""
  var answer = ""
  var usersResponse = ""



  var skipped = 0
  var userSelectedAnswer = -1
  var userSelectedOption = ""
}
