package org.flipacademy.mvps.classrooms

import com.google.gson.annotations.SerializedName

data class AllClassesResponse(val status: String, val data: List<ClassItem>)

data class ClassItem(val id: Int, @SerializedName("class") val className: String)


data class AllSubjectsResponse(val status: String, val data: List<SubjectItem>)

data class SubjectItem(val id: Int, @SerializedName("subject") val subjectName: String)