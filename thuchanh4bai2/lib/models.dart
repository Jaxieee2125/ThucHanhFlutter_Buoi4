// models.dart

// Thông tin môn học/lịch học
class Schedule {
  final String id;
  final String subject;
  final String time;
  final String room;

  Schedule({required this.id, required this.subject, required this.time, required this.room});

  factory Schedule.fromFirestore(Map<String, dynamic> data, String id) {
    return Schedule(
      id: id,
      subject: data['subject'] ?? '',
      time: data['time'] ?? '',
      room: data['room'] ?? '',
    );
  }
}

// Thông tin điểm số
class Grade {
  final String id;
  final String subject;
  final double score;
  final String type; // Ví dụ: Giữa kỳ, Cuối kỳ

  Grade({required this.id, required this.subject, required this.score, required this.type});

  factory Grade.fromFirestore(Map<String, dynamic> data, String id) {
    return Grade(
      id: id,
      subject: data['subject'] ?? '',
      score: (data['score'] ?? 0).toDouble(),
      type: data['type'] ?? '',
    );
  }
}