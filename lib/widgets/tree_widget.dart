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
      return '시들음';
    }
    
    if (session.status == FocusSessionStatus.completed) {
      return '완성!';
    }
    
    // 진행률 표시
    final progressPercent = (session.progress * 100).round();
    return '$progressPercent%';
  }

  Color _getBackgroundColor() {
    if (session.status == FocusSessionStatus.abandoned) {
      return Colors.brown.shade50;
    }
    
    if (session.status == FocusSessionStatus.completed) {
      return Colors.green.shade50;
    }
    
    // 진행률에 따른 색상 변화
    final progress = session.progress.clamp(0.0, 1.0); // 안전한 범위로 제한
    if (progress < 0.25) {
      return Colors.yellow.shade50; // 씨앗 단계
    } else if (progress < 0.50) {
      return Colors.lightGreen.shade50; // 새싹 단계
    } else if (progress < 0.75) {
      return Colors.green.shade100; // 작은 나무 단계
    } else {
      return Colors.green.shade50; // 큰 나무 단계
    }
  }

  @override
  Widget build(BuildContext context) {
    // 안전한 크기 설정
    final safeSize = size.clamp(10.0, 500.0);
    
    // 기본값 설정 (session은 required이므로 null이 될 수 없음)

    final treeEmoji = _getTreeEmoji();
    final statusText = _getStatusText();
    final backgroundColor = _getBackgroundColor();

    return SizedBox(
      width: safeSize,
      height: safeSize,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: session.status == FocusSessionStatus.abandoned 
                ? Colors.brown.shade200
                : Colors.green.shade200,
            width: 2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(safeSize * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 나무 이모지
              Flexible(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    treeEmoji,
                    style: TextStyle(
                      fontSize: safeSize * 0.35, // 이모지 크기 조정
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: safeSize * 0.02),
              
              // 상태 텍스트
              Flexible(
                flex: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: safeSize * 0.08,
                      fontWeight: FontWeight.w600,
                      color: session.status == FocusSessionStatus.abandoned 
                          ? Colors.brown.shade600
                          : Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // 진행 중일 때만 진행률 바 표시
              if (session.status == FocusSessionStatus.running) ...[
                SizedBox(height: safeSize * 0.02),
                Flexible(
                  flex: 1,
                  child: Container(
                    width: safeSize * 0.5,
                    height: safeSize * 0.025,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(safeSize * 0.0125),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(safeSize * 0.0125),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (session.progress * 1.0).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(safeSize * 0.0125),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 