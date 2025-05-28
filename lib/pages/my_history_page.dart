import 'package:flutter/material.dart';

// Constants imports
import '../constants/app_colors.dart';

// Models imports
import '../models/models.dart';

class MyHistoryPage extends StatefulWidget {
  final UserModel currentUser;
  
  const MyHistoryPage({super.key, required this.currentUser});

  @override
  State<MyHistoryPage> createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '내 기록',
          style: TextStyle(
            color: AppColors.purple700,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
              Icons.history,
              size: 64,
              color: AppColors.purple400,
            ),
            const SizedBox(height: 16),
            Text(
              '기록 기능 준비 중입니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.purple700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '곧 상세한 기록을 확인하실 수 있어요!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey600,
              ),
              ),
          ],
        ),
      ),
    );
  }
} 