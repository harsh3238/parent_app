package com.stucare.cloud_parent.retrofit

import okhttp3.OkHttpClient
import okhttp3.RequestBody
import okhttp3.ResponseBody
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Call
import retrofit2.Retrofit
import retrofit2.http.*
import java.util.concurrent.TimeUnit


interface NetworkClient {

    @FormUrlEncoded
    @POST("api_v1/student/requests/get_live_classes.php")
    fun getLiveClasses(
        @Field("school_id") userId: Int,
        @Field("stucare_id") stucareId: Int,
        @Field("active_session") accessToken: String,
        @Field("upcoming") upcoming: String = ""
    ): Call<String>

    @FormUrlEncoded
    @POST("api_v1/student/requests/get_online_tests.php")
    fun getSchoolTests(
        @Field("school_id") userId: Int,
        @Field("stucare_id") stucareId: Int,
        @Field("active_session") accessToken: String
    ): Call<String>

    @FormUrlEncoded
    @POST("api_v1/student/requests/get_subject_for_student.php")
    fun getVideoLessonSubjects(
        @Field("stucare_id") stucareId: Int,
        @Field("active_session") accessToken: String
    ): Call<String>


    @FormUrlEncoded
    @POST("api_v1/student/requests/get_video_chapters.php")
    fun getVideoChapters(
        @Field("subject_id") subjectId: String,
        @Field("active_session") accessToken: String
    ): Call<String>


    @FormUrlEncoded
    @POST("api_v1/student/requests/get_video_lessons.php")
    fun getVideoLessons(
        @Field("chapter_id") chapterId: String,
        @Field("active_session") accessToken: String
    ): Call<String>


    @FormUrlEncoded
    @POST("api_v1/student/requests/get_test_questions.php")
    fun getOptionalTestQuestions(@Field("test_id") testId: String,
                                 @Field("active_session") accessToken: String): Call<String>

    @FormUrlEncoded
    @POST
    fun getSignedUrlForS3(@Url url: String, @Field("object_key") testId: String): Call<String>


    @PUT
    fun uploadS3(@Url url: String, @Body file: RequestBody): Call<String>

    @FormUrlEncoded
    @POST("api_v1/student/requests/save_test_submission.php")
    fun saveTest(
        @Field("stucare_id") stucareId: String,
        @Field("test_id") testId: String,
        @Field("q_count") qCount: String,
        @Field("c_count") cCount: String,
        @Field("a_count") aCount: String,
        @Field("data") allQuestionData: String,
        @Field("time_spent") timeSpent: String,
        @Field("file_key") fileKey: String,
        @Field("school_id") schoolId: String,
        @Field("active_session") accessToken: String
        ): Call<String>

    @FormUrlEncoded
    @POST("api_v2/schools/requests/get_subjective_question_paper.php")
    fun getSubjectiveTest(@Field("test_id") testId: String): Call<String>

    @GET
    fun downloadFile(@Url url: String): Call<ResponseBody>


    @FormUrlEncoded
    @POST("api_v2/schools/requests/save_subjective_test_submission.php")
    fun saveSubjectiveTests(
        @Field("user_id") userId: String,
        @Field("test_id") testId: String,
        @Field("time_spent") timeSpent: String,
        @Field("file_key") fileKey: String
    ): Call<String>

    @FormUrlEncoded
    @POST("api_v1/student/requests/mark_class_attendance.php")
    fun markLiveClassAttendance(
        @Field("stucare_id") userId: String,
        @Field("class_id") classId: String,
        @Field("active_session") accessToken: String
    ): Call<String>

    @FormUrlEncoded
    @POST("api_v1/student/requests/get_objective_test_report.php")
    fun getObjectiveTestReport(
        @Field("stucare_id") stucareId: String,
        @Field("test_id") testId: String,
        @Field("active_session") accessToken: String
    ): Call<String>

    abstract fun getOptionalTestQuestions(testId: String?): Call<String>

    companion object {
        var baseUrl: String = "https://demo.stucarecloud.com/"

        fun create(): NetworkClient {
            return getRetrofit().create(NetworkClient::class.java)
        }

        private fun getRetrofit(): Retrofit {
            val okHttpBuilder = OkHttpClient.Builder()
            val loggingInterceptor = HttpLoggingInterceptor()
            loggingInterceptor.level = HttpLoggingInterceptor.Level.BODY
            okHttpBuilder.addInterceptor(loggingInterceptor)
            okHttpBuilder.connectTimeout(60, TimeUnit.SECONDS)
            okHttpBuilder.writeTimeout(60, TimeUnit.SECONDS)
            okHttpBuilder.readTimeout(60, TimeUnit.SECONDS)


            return Retrofit.Builder()
                .baseUrl(baseUrl)
                .addConverterFactory(ToStringConverterFactory())
                .client(okHttpBuilder.build()).build()
        }
    }

}