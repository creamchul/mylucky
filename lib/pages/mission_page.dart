import 'package:flutter/material.dart';

// Constants imports
import '../constants/app_colors.dart';

// Models imports
import '../models/models.dart';

class MissionPage extends StatefulWidget {
  final UserModel currentUser;
  
  const MissionPage({super.key, required this.currentUser});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '오늘의 미션',
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
              Icons.construction,
              size: 64,
              color: AppColors.purple400,
            ),
            const SizedBox(height: 16),
                                Text(
              '미션 기능 준비 중입니다',
                                  style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.purple700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
              '곧 멋진 미션들을 만나보실 수 있어요!',
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
