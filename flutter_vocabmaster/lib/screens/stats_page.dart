import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/animated_background.dart';
import '../widgets/bottom_nav.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(isDark: true),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'İstatistiklerim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Top Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildTopStatCard(
                          icon: Icons.menu_book,
                          value: '124',
                          label: 'Toplam Kelime',
                          color: const Color(0xFF06b6d4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTopStatCard(
                          icon: Icons.local_fire_department,
                          value: '7',
                          label: 'Gün Serisi',
                          color: const Color(0xFF06b6d4),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Weekly Progress Chart
                  _buildWeeklyProgressCard(),
                  
                  const SizedBox(height: 24),
                  
                  // XP Progress Chart
                  _buildXPProgressCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Category Distribution
                  _buildCategoryDistribution(),
                  
                  const SizedBox(height: 24),
                  
                  // Achievements
                  _buildAchievements(),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildTopStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard() {
    final weeklyData = [
      {'day': 'Pzt', 'value': 5.0},
      {'day': 'Sal', 'value': 7.0},
      {'day': 'Çar', 'value': 3.0},
      {'day': 'Per', 'value': 6.0},
      {'day': 'Cum', 'value': 4.0},
      {'day': 'Cmt', 'value': 8.0},
      {'day': 'Paz', 'value': 2.0},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF06b6d4), size: 20),
              SizedBox(width: 8),
              Text(
                'Haftalık İlerleme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weeklyData[value.toInt()]['day'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['value'] as double,
                        color: const Color(0xFF06b6d4),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgressCard() {
    final xpData = [
      FlSpot(0, 150),
      FlSpot(1, 210),
      FlSpot(2, 90),
      FlSpot(3, 180),
      FlSpot(4, 120),
      FlSpot(5, 240),
      FlSpot(6, 60),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars, color: Color(0xFF06b6d4), size: 20),
              SizedBox(width: 8),
              Text(
                'XP Gelişimi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 300,
                lineBarsData: [
                  LineChartBarData(
                    spots: xpData,
                    isCurved: true,
                    color: const Color(0xFF06b6d4),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF06b6d4),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF06b6d4).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    final categories = [
      {'name': 'Noun', 'count': 45, 'total': 124},
      {'name': 'Verb', 'count': 38, 'total': 124},
      {'name': 'Adjective', 'count': 32, 'total': 124},
      {'name': 'Adverb', 'count': 9, 'total': 124},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category, color: Color(0xFF06b6d4), size: 20),
              SizedBox(width: 8),
              Text(
                'Kategori Dağılımı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...categories.map((cat) {
            final percentage = ((cat['count'] as int) / (cat['total'] as int) * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cat['name'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '${cat['count']} kelime ($percentage%)',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (cat['count'] as int) / (cat['total'] as int),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06b6d4)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      {'title': 'İlk Adım', 'desc': 'İlk kelimeni öğrendin', 'icon': '🎯', 'unlocked': true},
      {'title': '7 Gün Serisi', 'desc': '7 gün üst üste çalıştın', 'icon': '🔥', 'unlocked': true},
      {'title': '100 Kelime', 'desc': '100 kelime öğrendin', 'icon': '💯', 'unlocked': true},
      {'title': 'Haftalık Kahraman', 'desc': 'Haftada 50 kelime öğren', 'icon': '⭐', 'unlocked': false},
      {'title': 'Seviye 10', 'desc': '10. seviyeye ulaş', 'icon': '🏆', 'unlocked': false},
      {'title': 'Usta', 'desc': '500 kelime öğren', 'icon': '👑', 'unlocked': false},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e3a8a).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFF06b6d4), size: 20),
              SizedBox(width: 8),
              Text(
                'Başarılar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final unlocked = achievement['unlocked'] as bool;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: unlocked 
                      ? const Color(0xFF3b82f6).withOpacity(0.3)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked 
                        ? const Color(0xFF3b82f6)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      achievement['icon'] as String,
                      style: TextStyle(
                        fontSize: 40,
                        color: unlocked ? null : Colors.white.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement['title'] as String,
                      style: TextStyle(
                        color: unlocked ? Colors.white : Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement['desc'] as String,
                      style: TextStyle(
                        color: unlocked ? Colors.white70 : Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
