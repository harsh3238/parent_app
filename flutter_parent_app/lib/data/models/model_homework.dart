class ModelHomework {
  int id;
  String assignmentTitle;
  String subjectName;
  String assignmentType;
  String content;
  int attachmentCount;
  String startDate;
  String submissionDate;
  String timestampCreated;
  String givenBy;
  String maxMarks;
  int submissionsRequired;

  ModelHomework(
      this.id,
      this.assignmentTitle,
      this.subjectName,
      this.assignmentType,
      this.content,
      this.attachmentCount,
      this.startDate,
      this.submissionDate,
      this.timestampCreated,
      this.givenBy,
      this.maxMarks,
      this.submissionsRequired);

  factory ModelHomework.fromJson(Map<String, dynamic> item) {
    return ModelHomework(
        int.parse(item['id']),
        item['assignment_title'],
        item['subject_name'],
        item['assignment_type'],
        item['content'],
        int.parse(item['attachment_count']),
        item['start_date'],
        item['submission_date'],
        item['timestamp_created'],
        item['given_by'],
        item['max_marks'],
        int.parse(item['submission_required']));
  }
}
