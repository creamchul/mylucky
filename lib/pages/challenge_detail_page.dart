import 'package:flutter/material.dart';

// Constants imports
import '../constants/app_colors.dart';

class ChallengeDetailPage extends StatefulWidget {
  final dynamic challenge;
  
  const ChallengeDetailPage({
    super.key, 
    required this.challenge,
  });

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.challenge.title,
          style: TextStyle(
            color: AppColors.purple700,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
              '챌린지 상세',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                color: AppColors.purple700,
                          ),
                        ),
            const SizedBox(height: 16),
                  Text(
                    widget.challenge.description,
                    style: TextStyle(
                      fontSize: 16,
                color: AppColors.grey600,
                    ),
                  ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
                style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple400,
                  foregroundColor: Colors.white,
              ),
              child: const Text('돌아가기'),
                          ),
          ],
        ),
      ),
    );
  }
} 