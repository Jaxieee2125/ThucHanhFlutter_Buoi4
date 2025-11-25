import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'models.dart'; // File chứa model Grade đã làm ở bước trước

class GradesChart extends StatelessWidget {
  final List<Grade> grades;

  const GradesChart({super.key, required this.grades});

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return const Center(child: Text("Chưa có dữ liệu điểm để vẽ biểu đồ"));
    }

    return AspectRatio(
      aspectRatio: 1.5, // Tỉ lệ khung hình biểu đồ
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 10, // Điểm tối đa là 10
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.blueAccent,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String subject = grades[group.x.toInt()].subject;
                  return BarTooltipItem(
                    '$subject\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: (rod.toY).toString()),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    // Hiển thị tên tắt của môn học ở trục hoành
                    if (value.toInt() < grades.length) {
                      // Lấy 3 chữ cái đầu của tên môn học
                      String name = grades[value.toInt()].subject;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          name.length > 3 ? name.substring(0, 3) : name,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            barGroups: grades.asMap().entries.map((entry) {
              int index = entry.key;
              Grade grade = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: grade.score,
                    color: grade.score >= 5 ? Colors.green : Colors.red, // Xanh nếu đậu, Đỏ nếu rớt
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}