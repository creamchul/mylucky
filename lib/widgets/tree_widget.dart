import 'package:flutter/material.dart';
import '../models/focus_session_model.dart';

class TreeWidget extends StatelessWidget {
  final FocusSessionModel session;
  final double size;

  const TreeWidget({super.key, required this.session, this.size = 150.0});

  String _getTreeEmoji() {
    // 포기한 경우 시든 나무
    if (session.status == FocusSessionStatus.abandoned) {
      return '🥀'; // 시든 꽃
    }
    
    // 완료된 경우 큰 나무
    if (session.status == FocusSessionStatus.completed) {
      return '🌳'; // 큰 나무
    }
    
    // 진행 중인 경우 성장 단계에 따라
    switch (session.growthStage) {
      case 1:
        return '🌱'; // 새싹 (0-25%)
      case 2:
        return '🌿'; // 잎사귀 (25-50%)
      case 3:
        return '🌲'; // 작은 나무 (50-75%)
      case 4:
      default:
        return '🌳'; // 큰 나무 (75-100%)
    }
  }

  String _getStatusText() {
    if (session.status == FocusSessionStatus.abandoned) {
      return '시들었어요 😢';
    }
    
    if (session.status == FocusSessionStatus.completed) {
      return '완성! 🎉';
    }
    
    // 진행률 표시
    final progressPercent = (session.progress * 100).round();
    return '성장 중... $progressPercent%';
  }

  Color _getBackgroundColor() {
    if (session.status == FocusSessionStatus.abandoned) {
      return Colors.brown.withOpacity(0.1);
    }
    
    if (session.status == FocusSessionStatus.completed) {
      return Colors.green.withOpacity(0.2);
    }
    
    // 진행률에 따른 색상 변화
    final progress = session.progress;
    if (progress < 0.25) {
      return Colors.yellow.withOpacity(0.1); // 씨앗 단계
    } else if (progress < 0.50) {
      return Colors.lightGreen.withOpacity(0.1); // 새싹 단계
    } else if (progress < 0.75) {
      return Colors.green.withOpacity(0.15); // 작은 나무 단계
    } else {
      return Colors.green.withOpacity(0.2); // 큰 나무 단계
    }
  }

  @override
  Widget build(BuildContext context) {
    final treeEmoji = _getTreeEmoji();
    final statusText = _getStatusText();
    final backgroundColor = _getBackgroundColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: session.status == FocusSessionStatus.abandoned 
              ? Colors.brown.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 나무 이모지
          Text(
            treeEmoji,
            style: TextStyle(
              fontSize: size * 0.4, // 이모지 크기
            ),
          ),
          SizedBox(height: size * 0.05),
          // 상태 텍스트
          Text(
            statusText,
            style: TextStyle(
              fontSize: size * 0.08,
              fontWeight: FontWeight.w600,
              color: session.status == FocusSessionStatus.abandoned 
                  ? Colors.brown.shade600
                  : Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          // 진행 중일 때만 진행률 바 표시
          if (session.status == FocusSessionStatus.running) ...[
            SizedBox(height: size * 0.05),
            Container(
              width: size * 0.6,
              height: size * 0.03,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(size * 0.015),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: session.progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(size * 0.015),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 