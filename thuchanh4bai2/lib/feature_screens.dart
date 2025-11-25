// feature_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services.dart';
import 'models.dart';
import 'package:thuchanh4bai2/grades_chart.dart';

// Màn hình Lịch học
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<Schedule>>(
      stream: db.getSchedules(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Lỗi tải dữ liệu"));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final schedules = snapshot.data ?? [];
        if (schedules.isEmpty) return const Center(child: Text("Chưa có lịch học"));

        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final item = schedules[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Phòng: ${item.room}"),
                trailing: Text(item.time),
              ),
            );
          },
        );
      },
    );
  }
}

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<Grade>>(
      stream: db.getGrades(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("Lỗi: ${snapshot.error}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final grades = snapshot.data ?? [];

        return Column(
          children: [
            // 1. Phần biểu đồ
            const SizedBox(height: 20),
            const Text("Biểu đồ học tập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 250, // Chiều cao cố định cho biểu đồ
              child: GradesChart(grades: grades),
            ),
            
            // 2. Phần bảng điểm chi tiết
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
            columns: const [
              DataColumn(label: Text('Môn học')),
              DataColumn(label: Text('Loại điểm')),
              DataColumn(label: Text('Điểm số')),
            ],
            rows: grades.map((g) => DataRow(cells: [
              DataCell(Text(g.subject)),
              DataCell(Text(g.type)),
              DataCell(Text(g.score.toString(), 
                style: TextStyle(
                  color: g.score >= 5 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold
                )
              )),
            ])).toList(),)
              ),
            ),
          ],
        );
      },
    );
  }
}