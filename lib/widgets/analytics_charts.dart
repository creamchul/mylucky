import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsCharts {
  
  /// 시간대별 집중 패턴 차트 (24시간)
  static Widget buildHourlyChart(Map<int, double> data, Color color) {
    final spots = data.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            horizontalInterval: 30,
            verticalInterval: 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  final hour = value.toInt();
                  if (hour % 4 == 0) {
                    return Text(
                      '${hour}시',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}분',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: 0,
          maxX: 23,
          minY: 0,
          maxY: data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) + 30 : 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 요일별 집중 패턴 차트 (막대 차트)
  static Widget buildWeeklyChart(Map<int, double> data, Color color) {
    final weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
    
    final barGroups = data.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) + 30 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${weekdays[group.x]} : ${rod.toY.toInt()}분',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 1 && index <= 7) {
                    return Text(
                      weekdays[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return Container();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}분',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 30,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }
  
  /// 월별/일별 집중 패턴 차트 (라인 차트)
  static Widget buildMonthlyChart(Map<int, double> data, Color color, String period) {
    final spots = data.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: 30,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: period == 'month' ? 5 : 2,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  if (period == 'month' && day % 5 == 0) {
                    return Text(
                      '${day}일',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  } else if (period == 'year' && day % 2 == 0) {
                    return Text(
                      '${day}월',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}분',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: period == 'month' ? 1 : 1,
          maxX: period == 'month' ? 31 : 12,
          minY: 0,
          maxY: data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) + 30 : 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 비교 차트 (현재 vs 이전)
  static Widget buildComparisonChart(
    Map<int, double> currentData,
    Map<int, double> previousData,
    Color currentColor,
    Color previousColor,
    String chartType,
  ) {
    if (chartType == 'bar') {
      return _buildComparisonBarChart(currentData, previousData, currentColor, previousColor);
    } else {
      return _buildComparisonLineChart(currentData, previousData, currentColor, previousColor);
    }
  }
  
  static Widget _buildComparisonLineChart(
    Map<int, double> currentData,
    Map<int, double> previousData,
    Color currentColor,
    Color previousColor,
  ) {
    final currentSpots = currentData.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    final previousSpots = previousData.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
    
    final maxY = [
      ...currentData.values,
      ...previousData.values,
    ].fold<double>(0, (a, b) => a > b ? a : b) + 30;
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            drawHorizontalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}분',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            // 현재 기간 데이터
            LineChartBarData(
              spots: currentSpots,
              isCurved: true,
              color: currentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: currentColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
            ),
            // 이전 기간 데이터
            LineChartBarData(
              spots: previousSpots,
              isCurved: true,
              color: previousColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [5, 5],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 2,
                  color: previousColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  static Widget _buildComparisonBarChart(
    Map<int, double> currentData,
    Map<int, double> previousData,
    Color currentColor,
    Color previousColor,
  ) {
    final barGroups = currentData.keys.map((key) {
      return BarChartGroupData(
        x: key,
        barRods: [
          BarChartRodData(
            toY: currentData[key] ?? 0,
            color: currentColor,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: previousData[key] ?? 0,
            color: previousColor,
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
    
    final maxY = [
      ...currentData.values,
      ...previousData.values,
    ].fold<double>(0, (a, b) => a > b ? a : b) + 30;
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}분',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }
  
  /// 트렌드 차트 (최근 N일 집중 시간)
  static Widget buildTrendChart(List<Map<String, dynamic>> trendData, Color color) {
    final spots = trendData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(index.toDouble(), data['totalMinutes']);
    }).toList();
    
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: 30,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: trendData.length > 7 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < trendData.length) {
                    final date = trendData[index]['date'] as DateTime;
                    return Text(
                      '${date.month}/${date.day}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}분',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          minX: 0,
          maxX: (trendData.length - 1).toDouble(),
          minY: 0,
          maxY: trendData.isNotEmpty 
              ? trendData.map((e) => e['totalMinutes'] as double).reduce((a, b) => a > b ? a : b) + 30
              : 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 2,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 범용 막대 차트 (시간대별, 일별, 월별 등에 사용)
  static Widget buildBarChart(
    Map<int, double> data, 
    Color color, 
    String Function(int) getLabelText,
    String tooltipSuffix,
    {double? maxY, double barWidth = 12}
  ) {
    final barGroups = data.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: color,
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
    
    final calculatedMaxY = maxY ?? (data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) + 30 : 100);
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: calculatedMaxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final labelText = getLabelText(group.x);
                final displayLabel = labelText.isEmpty ? '${group.x}' : labelText;
                return BarTooltipItem(
                  '$displayLabel : ${rod.toY.toInt()}$tooltipSuffix',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  final labelText = getLabelText(index);
                  
                  bool shouldShow = false;
                  if (tooltipSuffix == '분') {
                    if (labelText.contains('시')) {
                      shouldShow = index % 4 == 0 || index == 23;
                    } else if (labelText.contains('일')) {
                      shouldShow = index % 5 == 0 || index == 1;
                    } else if (labelText.contains('월')) {
                      shouldShow = index >= 1 && index <= 12;
                    }
                  }
                  
                  if (shouldShow) {
                    return Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}분',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 30,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  /// 가로 막대 비교 차트 (기간 비교용)
  static Widget buildHorizontalComparisonChart(
    Map<int, double> currentData,
    Map<int, double> previousData,
    Color currentColor,
    Color previousColor,
    String periodType,
  ) {
    final List<String> categories = [];
    final List<Map<String, dynamic>> chartData = [];
    
    // 카테고리 라벨 생성
    switch (periodType) {
      case 'day':
        // 주요 시간대만 표시 (6시간 간격)
        for (int hour = 0; hour <= 18; hour += 6) {
          categories.add('${hour}시');
          chartData.add({
            'category': '${hour}시',
            'current': currentData[hour] ?? 0.0,
            'previous': previousData[hour] ?? 0.0,
          });
        }
        break;
      case 'week':
        final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
        for (int i = 1; i <= 7; i++) {
          categories.add(weekdays[i-1]);
          chartData.add({
            'category': weekdays[i-1],
            'current': currentData[i] ?? 0.0,
            'previous': previousData[i] ?? 0.0,
          });
        }
        break;
      case 'month':
        // 주요 날짜만 표시 (일주일 간격)
        for (int day = 1; day <= 29; day += 7) {
          categories.add('${day}일');
          chartData.add({
            'category': '${day}일',
            'current': currentData[day] ?? 0.0,
            'previous': previousData[day] ?? 0.0,
          });
        }
        break;
      case 'year':
        final months = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
        for (int i = 1; i <= 12; i++) {
          categories.add(months[i-1]);
          chartData.add({
            'category': months[i-1],
            'current': currentData[i] ?? 0.0,
            'previous': previousData[i] ?? 0.0,
          });
        }
        break;
    }
    
    final maxValue = chartData.fold(0.0, (max, data) {
      final currentMax = data['current'] as double;
      final previousMax = data['previous'] as double;
      return [max, currentMax, previousMax].reduce((a, b) => a > b ? a : b);
    });
    
    return Container(
      height: chartData.length * 60.0 + 40, // 각 항목당 60px + 여백
      padding: const EdgeInsets.all(16),
      child: Column(
        children: chartData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final category = data['category'] as String;
          final current = data['current'] as double;
          final previous = data['previous'] as double;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // 카테고리 라벨
                  SizedBox(
                    width: 40,
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 차트 영역
                  Expanded(
                    child: Column(
                      children: [
                        // 현재 기간 막대
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '현재',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: currentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: maxValue > 0 ? (current / maxValue) : 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: currentColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${current.toInt()}분',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: currentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 2),
                        
                        // 이전 기간 막대
                        Expanded(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '이전',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: previousColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: maxValue > 0 ? (previous / maxValue) : 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: previousColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${previous.toInt()}분',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: previousColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 간단한 3개 막대 비교 차트
  static Widget buildSimpleComparisonChart(
    double currentTotal,
    double previousTotal,
    double beforePreviousTotal,
    String currentLabel,
    String previousLabel,
    String beforePreviousLabel,
    Color currentColor,
    Color previousColor,
    Color beforePreviousColor,
  ) {
    final maxValue = [currentTotal, previousTotal, beforePreviousTotal].reduce((a, b) => a > b ? a : b);
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 현재 기간
          Expanded(
            child: _buildSimpleBarRow(
              currentLabel,
              currentTotal,
              maxValue,
              currentColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // 이전 기간
          Expanded(
            child: _buildSimpleBarRow(
              previousLabel,
              previousTotal,
              maxValue,
              previousColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // 전전 기간
          Expanded(
            child: _buildSimpleBarRow(
              beforePreviousLabel,
              beforePreviousTotal,
              maxValue,
              beforePreviousColor,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSimpleBarRow(
    String label,
    double value,
    double maxValue,
    Color color,
  ) {
    return Row(
      children: [
        // 라벨
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 16),
        
        // 막대와 수치
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: maxValue > 0 ? (value / maxValue) : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: Text(
                  '${value.toInt()}분',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 카테고리 분석 원형 차트
  static Widget buildCategoryPieChart(
    Map<String, Map<String, dynamic>> categoryData,
    double totalMinutes,
  ) {
    if (categoryData.isEmpty || totalMinutes == 0) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                '카테고리 데이터가 없습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sections = categoryData.entries.map((entry) {
      final categoryName = entry.key;
      final data = entry.value;
      final minutes = data['minutes'] as double;
      final color = data['color'] as Color;
      final percentage = (minutes / totalMinutes * 100);
      
      return PieChartSectionData(
        color: color,
        value: minutes,
        title: '${percentage.toInt()}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: null,
      );
    }).toList();

    return Container(
      height: 250,
      child: Row(
        children: [
          // 원형 차트
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 30,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // 터치 이벤트 처리 (선택사항)
                  },
                ),
              ),
            ),
          ),
          
          // 범례
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categoryData.entries.map((entry) {
                final categoryName = entry.key;
                final data = entry.value;
                final minutes = data['minutes'] as double;
                final color = data['color'] as Color;
                final percentage = (minutes / totalMinutes * 100);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${minutes.toInt()}분 (${percentage.toInt()}%)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
} 