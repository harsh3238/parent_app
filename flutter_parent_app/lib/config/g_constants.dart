import 'package:click_campus_parent/data/app_data.dart';

class GConstants {

  static const String API_VERSION = "api_v2";

  static const MULTIPLE_SCHOOLS = false;
  static const MULTIPLE_SCHOOLS_LIST = [
    {
      'school_id': 1,
      'school_name': 'Demo Public School',
      'url': 'https://demo.stucarecloud.in/'
    }
  ];
  static const _SCHOOL_ID = 1;

  static Future<int> schoolId() async {
    var i = await AppData().getNormalSchoolId();
    if (i != null && i.isNotEmpty) return int.parse(i);
    return _SCHOOL_ID;
  }

  static const SCHOOL_NAME = "Demo Public School";

  static String SCHOOL_ROOT = "https://demo.stucarecloud.in/";
  static String SCHOOL_ROOT_AUTH = "demo.stucarecloud.in";

  static const _SCHOOL_INFO_ROOT = "https://schools.stucarecloud.in/";
  static const _SCHOOL_INFO_SCHOOL_DATE_ROUTE = API_VERSION+"/requests/school_info.php";

  static const _SUPER_USER_ROUTE = API_VERSION+"/requests/login_super_user.php";
  static const _SUPER_USER_OTP_VERIFY = API_VERSION+ "/requests/verify_otp_super_user.php";

  static const _LOGIN_ROUTE = API_VERSION+"/student/requests/login.php";
  static const _OTP_VERIFY_ROUTE = API_VERSION+ "/student/requests/verify_otp.php";
  static const _OTP_RESEND_ROUTE = API_VERSION+ "/student/requests/resend_otp.php";
  static const _LOGIN_REPORT_ROUTE = API_VERSION+ "/student/requests/login_report.php";
  static const _VALIDATE_LOGIN_ROUTE = API_VERSION+ "/student/requests/validate_login_session.php";
  static const _GET_SIBLINGS_ROUTE = API_VERSION+ "/student/requests/get_siblings.php";
  static const _GET_PROFILE = API_VERSION+ "/student/requests/get_profile.php";
  static const _GET_ACTIVE_MODULES = API_VERSION+ "/student/requests/get_active_modules.php";
  static const _ADD_REFERENCE_ROUTE = API_VERSION+ "/student/requests/add_reference.php";
  static const _GET_CLASSES_ROUTE = API_VERSION+ "/student/requests/get_all_classes.php";
  static const _GET_SYLLABUS_ROUTE = API_VERSION+ "/student/requests/get_syllabus_v2.php";
  static const _GET_SCHOOL_INFO_ROUTE = API_VERSION+ "/student/requests/get_school_info1.php";
  static const _GET_DASH_SLIDER_ROUTE = API_VERSION+ "/student/requests/get_dash_sliders.php";
  static const _GET_SESSIONS_ROUTE = API_VERSION+ "/admin/requests/get_all_sessions.php";
  static const _MSG_THREAD_ROUTE = API_VERSION+ "/student/requests/get_message_threads.php";
  static const _MESSAGES_ROUTE = API_VERSION+ "/student/requests/get_messages.php";
  static const _MESSAGES_ALL_ROUTE = API_VERSION+ "/student/requests/get_messages_all_v2.php";
  static const _MESSAGES_ATTACHMENT_ROUTE = API_VERSION+ "/student/requests/get_message_attaachments.php";

  static const _HOMEWORK_ROUTE = API_VERSION+ "/student/requests/get_homework.php";
  static const _HOMEWORK_ATTACHMENT_ROUTE = API_VERSION+ "/student/requests/homework_attachments.php";
  static const _SCHOLASTIC_TERMS = API_VERSION+ "/student/requests/exam_terms.php";
  static const _STUDENTS_EXAM_DATA = API_VERSION+ "/student/requests/student_exam_data.php";
  static const _FLYERS = API_VERSION+ "/student/requests/get_flyer_v2.php";
  static const _FLASH_NEWS = API_VERSION+ "/student/requests/get_flash_news.php";
  static const _NORMAL_NEWS = API_VERSION+ "/student/requests/get_normal_news.php";
  static const _PHOTO_GALELRY = API_VERSION+ "/student/requests/get_gallery_data.php";
  static const _EVENTS = API_VERSION+ "/student/requests/get_events.php";
  static const _VIDEO_GALLERY = API_VERSION+ "/student/requests/get_video_gallery_data.php";
  static const _VOICE_CALL = API_VERSION+ "/student/requests/get_voice_calls.php";
  static const _ATTENDANCE = API_VERSION+ "/student/requests/get_attendance.php";
  static const _SCHOLASTIC_EXAMS = API_VERSION+ "/student/requests/exam_scholastic_exams.php";
  static const _ADD_LEAVE = API_VERSION+ "/student/requests/add_leave.php";
  static const _GET_LEAVE = API_VERSION+ "/student/requests/get_leave.php";
  static const _DELETE_LEAVE = API_VERSION+ "/student/requests/delete_leave.php";
  static const _GET_REF_ROUTE = API_VERSION+ "/student/requests/get_refs.php";
  static const _USERLIST_FOR_SUPER_USER = API_VERSION+ "/student/requests/get_users_for_super_user.php";
  static const _LOGIN_AS_ROUTE = API_VERSION+ "/student/requests/set_login_as.php";
  static const _SET_FIREBASE_ID_ROUTE = API_VERSION+ "/student/requests/set_firebase_id.php";
  static const _NOTIFICATIONS = API_VERSION+ "/student/requests/get_notifications.php";
  static const _GET_ANNOUNCEMENT_DETAILS = API_VERSION+ "/admin/requests/get_announcements_details.php";
  static const _UPDATE_MSG_SEEN = API_VERSION+ "/admin/requests/update_message_received.php";
  static const _ADD_HOMEWORk_SUBMISSION = API_VERSION+ "/student/requests/add_homework_submission.php";

  static const _HOMEWORK_SUBMISSIONS = API_VERSION+ "/student/requests/get_homework_submission.php";
  static const _HOMEWORK_SEEN = API_VERSION+ "/student/requests/update_homeowrk_received.php";
  static const _AFTER_FIREBASE_AUTH = API_VERSION+ "/student/requests/create_app_session.php";
  static const _LIVE_CLASSES = API_VERSION+ "/student/requests/get_live_classes.php";
  static const _DOWNLOADS = API_VERSION+ "/student/requests/get_downloads.php";
  static const _DISABLE_FLIP = API_VERSION+ "/student/requests/disbale_flip.php";
  static const _GET_FITNESS_DECLARATION = API_VERSION+ "/getDeclaration";
  static const _SAVE_FITNESS_DECLARATION = API_VERSION+ "/saveDeclaration";

  static setSchoolRootUrl(String rootUrl) {
    SCHOOL_ROOT = rootUrl;
    SCHOOL_ROOT_AUTH = rootUrl.substring(8, rootUrl.length);
  }

  static Future<String> getSchoolUrl() async {
    var i = await AppData().getNormalSchoolUrl();
    if (i != null && i.isNotEmpty) {
      SCHOOL_ROOT = i;
      SCHOOL_ROOT_AUTH = SCHOOL_ROOT.substring(8, SCHOOL_ROOT.length);
    }
    return SCHOOL_ROOT;
  }

  static String getBucketDirName() {
    return SCHOOL_ROOT.substring(
        SCHOOL_ROOT.indexOf("//") + 2, SCHOOL_ROOT.indexOf('.'));
  }

  static schoolDataRoute() =>
      _SCHOOL_INFO_ROOT + _SCHOOL_INFO_SCHOOL_DATE_ROUTE;

  static superUserRoute() => _SCHOOL_INFO_ROOT + _SUPER_USER_ROUTE;

  static superUserOtpVerifyRoute() =>
      _SCHOOL_INFO_ROOT + _SUPER_USER_OTP_VERIFY;

  static getUserListForSuperUser(String rootUrl) =>
      rootUrl + _USERLIST_FOR_SUPER_USER;

  static getLoginAsRoute(String rootUrl) => rootUrl + _LOGIN_AS_ROUTE;

  static loginRoute() => SCHOOL_ROOT + _LOGIN_ROUTE;

  static otpVerifyRoute() => SCHOOL_ROOT + _OTP_VERIFY_ROUTE;

  static resendOtpRoute() => SCHOOL_ROOT + _OTP_RESEND_ROUTE;

  static loginReportRoute() => SCHOOL_ROOT + _LOGIN_REPORT_ROUTE;

  static validateLoginRoute() => SCHOOL_ROOT + _VALIDATE_LOGIN_ROUTE;

  static getSiblingsRoute() => SCHOOL_ROOT + _GET_SIBLINGS_ROUTE;

  static getProfileRoute() => SCHOOL_ROOT + _GET_PROFILE;

  static getActiveModulesRoute() => SCHOOL_ROOT + _GET_ACTIVE_MODULES;

  static getAddReferenceRoute() => SCHOOL_ROOT + _ADD_REFERENCE_ROUTE;

  static getAllClassesRoute() => SCHOOL_ROOT + _GET_CLASSES_ROUTE;

  static getSyllabusRoute() => SCHOOL_ROOT + _GET_SYLLABUS_ROUTE;

  static getSchoolInfoRoute() => SCHOOL_ROOT + _GET_SCHOOL_INFO_ROUTE;

  static getDashSliderRoute() => SCHOOL_ROOT + _GET_DASH_SLIDER_ROUTE;

  static getSessionsRoute() => SCHOOL_ROOT + _GET_SESSIONS_ROUTE;

  static getMessageThreadsRoute() => SCHOOL_ROOT + _MSG_THREAD_ROUTE;

  static getMessagesRoute() => SCHOOL_ROOT + _MESSAGES_ROUTE;

  static getMessagesAllRoute() => SCHOOL_ROOT + _MESSAGES_ALL_ROUTE;

  static getMessagesAttachmentRoute() =>
      SCHOOL_ROOT + _MESSAGES_ATTACHMENT_ROUTE;

  static getHomeworkRoute() => SCHOOL_ROOT + _HOMEWORK_ROUTE;

  static getHomeworkAttachmentRoute() =>
      SCHOOL_ROOT + _HOMEWORK_ATTACHMENT_ROUTE;

  static getExamTerms() => SCHOOL_ROOT + _SCHOLASTIC_TERMS;

  static getStudentExamDateRoute() => SCHOOL_ROOT + _STUDENTS_EXAM_DATA;

  static getFlyersRoute() => SCHOOL_ROOT + _FLYERS;

  static getFlashNewsRoute() => SCHOOL_ROOT + _FLASH_NEWS;

  static getNormalNewsRoute() => SCHOOL_ROOT + _NORMAL_NEWS;

  static getPhotoGalleryRoute() => SCHOOL_ROOT + _PHOTO_GALELRY;

  static getEventsRoute() => SCHOOL_ROOT + _EVENTS;

  static getVideoGalleryRoute() => SCHOOL_ROOT + _VIDEO_GALLERY;

  static getVoiceCallsRoute() => SCHOOL_ROOT + _VOICE_CALL;

  static getAttendanceRoute() => SCHOOL_ROOT + _ATTENDANCE;

  static getScholasticExamsRoute() => SCHOOL_ROOT + _SCHOLASTIC_EXAMS;

  static getAddLeaveRoute() => SCHOOL_ROOT + _ADD_LEAVE;

  static getLeaveRoute() => SCHOOL_ROOT + _GET_LEAVE;

  static getDeleteLeaveRoute() => SCHOOL_ROOT + _DELETE_LEAVE;

  static getRefRoute() => SCHOOL_ROOT + _GET_REF_ROUTE;

  static getSetFirebaseIdRoute() => SCHOOL_ROOT + _SET_FIREBASE_ID_ROUTE;

  static getNotificationsRoute() => SCHOOL_ROOT + _NOTIFICATIONS;

  static getAnnouncementDetailsRoute() => SCHOOL_ROOT + _GET_ANNOUNCEMENT_DETAILS;

  static getUpdateSeenMessagesRoute() => SCHOOL_ROOT + _UPDATE_MSG_SEEN;

  static getAddHomeworkSubmissionsRoute() => SCHOOL_ROOT + _ADD_HOMEWORk_SUBMISSION;

  static getHomeworkSubmissionsRoute() => SCHOOL_ROOT + _HOMEWORK_SUBMISSIONS;

  static getHomeworkSeenRoute() => SCHOOL_ROOT + _HOMEWORK_SEEN;

  static afterFirebaseAuthRoute() => SCHOOL_ROOT + _AFTER_FIREBASE_AUTH;

  static getLiveClassesRoute() => SCHOOL_ROOT + _LIVE_CLASSES;

  static getDownloadsRoute() => SCHOOL_ROOT + _DOWNLOADS;

  static getDisbaleFLipRoute() => SCHOOL_ROOT + _DISABLE_FLIP;

  static getFitnessDeclarationRoute() => SCHOOL_ROOT + _GET_FITNESS_DECLARATION;

  static saveFitnessDeclarationRoute() => SCHOOL_ROOT + _SAVE_FITNESS_DECLARATION;


}
