import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/focus_session_model.dart';
import '../../models/user_model.dart';
import '../../services/focus_service.dart';
import '../../widgets/tree_widget.dart';
import 'home_page.dart'; // 같은 디렉토리의 home_page.dart 파일

class FocusingPage extends StatefulWidget {
  final FocusSessionModel session;
  final UserModel currentUser;

  const FocusingPage({
    super.key,
    required this.session,
    required this.currentUser,
  });

  @override
  State<FocusingPage> createState() => _FocusingPageState();
}

class _FocusingPageState extends State<FocusingPage> with TickerProviderStateMixin {
  late FocusSessionModel _currentSession;
  Timer? _timer;
  bool _isAbandoning = false;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    
    // 진행률 애니메이션 컨트롤러 초기화
    _progressController = AnimationController(
      duration: Duration(seconds: _currentSession.durationSecondsSet),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));
    
    // 진행률 애니메이션 시작
    _progressController.forward();
    
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentSession.remainingSeconds <= 0) {
        timer.cancel();
        _completeFocusSession();
      } else {
        setState(() {
          _currentSession = _currentSession.copyWith(
            elapsedSeconds: _currentSession.elapsedSeconds + 1,
          );
        });
      }
    });
  }

  Future<void> _completeFocusSession() async {
    try {
      setState(() {
        _currentSession = _currentSession.copyWith(
          status: FocusSessionStatus.completed,
          elapsedSeconds: _currentSession.durationSecondsSet
        );
      });
      
      final updatedSession = await FocusService.completeSession(_currentSession, widget.currentUser);
      if (mounted) {
        setState(() => _currentSession = updatedSession);
        _showResultDialog(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('집중 완료 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _showResultDialog(true);
      }
    }
  }

  Future<void> _abandonFocusSession() async {
    try {
      _timer?.cancel();
      setState(() => _isAbandoning = true);
      final preAbandonedSession = _currentSession.copyWith(status: FocusSessionStatus.abandoned);
      setState(() {
        _currentSession = preAbandonedSession;
      });

      final updatedSession = await FocusService.abandonSession(preAbandonedSession);
      if (mounted) {
        setState(() {
           _currentSession = updatedSession;
           _isAbandoning = false;
        });
        _showResultDialog(false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAbandoning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('집중 포기 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _showResultDialog(false);
      }
    }
  }

  void _showResultDialog(bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            success ? '🎉 집중 성공! 🎉' : '😥 아쉽지만... 😥',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: success ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: success ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TreeWidget(session: _currentSession, size: 120),
              ),
              const SizedBox(height: 20),
              Text(
                success
                    ? '${_currentSession.durationMinutesSet}분 집중을 완료하고\n나무를 성공적으로 키웠어요!'
                    : '나무가 시들었어요.\n다음번엔 꼭 성공해봐요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              if (success) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stars,
                        color: Colors.amber.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${_currentSession.durationMinutesSet}P 적립!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MyLuckyHomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? Colors.green.shade500 : Colors.orange.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '정말 포기하시겠어요?',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          '지금 포기하면 나무가 시들게 됩니다.\n계속 진행하시겠어요?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '계속 집중',
              style: TextStyle(
                color: Colors.teal.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '포기하기',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _abandonFocusSession();
      return true;
    }
    return false;
  }

  void _skipFiveMinutes() {
    if (!kDebugMode) return;
    
    setState(() {
      final newElapsedSeconds = _currentSession.elapsedSeconds + 300;
      _currentSession = _currentSession.copyWith(
        elapsedSeconds: newElapsedSeconds >= _currentSession.durationSecondsSet 
            ? _currentSession.durationSecondsSet 
            : newElapsedSeconds,
      );
    });
    
    FocusService.updateSession(_currentSession);
    
    if (_currentSession.remainingSeconds <= 0) {
      _timer?.cancel();
      _completeFocusSession();
    }
    
    if (kDebugMode) {
      print('테스트: 5분 앞당기기 - 현재 진행률: ${(_currentSession.progress * 100).round()}%');
    }
  }

  void _skipOneMinute() {
    if (!kDebugMode) return;
    
    setState(() {
      final newElapsedSeconds = _currentSession.elapsedSeconds + 60;
      _currentSession = _currentSession.copyWith(
        elapsedSeconds: newElapsedSeconds >= _currentSession.durationSecondsSet 
            ? _currentSession.durationSecondsSet 
            : newElapsedSeconds,
      );
    });
    
    FocusService.updateSession(_currentSession);
    
    if (_currentSession.remainingSeconds <= 0) {
      _timer?.cancel();
      _completeFocusSession();
    }
    
    if (kDebugMode) {
      print('테스트: 1분 앞당기기 - 현재 진행률: ${(_currentSession.progress * 100).round()}%');
    }
  }

  Color _getThemeColor() {
    return Colors.teal.shade400;
  }

  String _getMotivationalMessage() {
    final progress = _currentSession.progress;
    if (progress < 0.25) {
      return '좋은 시작이에요! 🌱';
    } else if (progress < 0.5) {
      return '잘하고 있어요! 🌿';
    } else if (progress < 0.75) {
      return '절반 이상 완료! 🌲';
    } else if (progress < 0.9) {
      return '거의 다 왔어요! 🌳';
    } else {
      return '마지막 스퍼트! 💪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_currentSession.remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_currentSession.remainingSeconds % 60).floor().toString().padLeft(2, '0');
    
    // 반응형 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            '집중 중...',
            style: TextStyle(
              color: _getThemeColor(),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.grey.shade600,
              ),
              onPressed: () async {
                final shouldPop = await _onWillPop();
                if (shouldPop) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAFAFA),
                Color(0xFFF0F9FF),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06, // 화면 너비의 6%
                        vertical: isVerySmallScreen ? 12 : 24,
                      ),
                      child: Column(
                        children: [
                          // 진행률 표시
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getThemeColor().withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // 진행률 바
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _progressAnimation,
                                    builder: (context, child) {
                                      return LinearProgressIndicator(
                                        value: _currentSession.progress,
                                        backgroundColor: Colors.transparent,
                                        valueColor: AlwaysStoppedAnimation<Color>(_getThemeColor()),
                                        borderRadius: BorderRadius.circular(4),
                                      );
                                    },
                                  ),
                                ),
                                
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                
                                // 진행률 텍스트
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${(_currentSession.progress * 100).round()}% 완료',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: _getThemeColor(),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        _getMotivationalMessage(),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 30 : 40)),
                          
                          // 메인 집중 영역 (반응형)
                          Container(
                            height: constraints.maxHeight * 0.5, // 사용 가능한 높이의 50%
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 큰 나무 위젯 (반응형)
                                Flexible(
                                  flex: 6,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: isVerySmallScreen ? 180 : (isSmallScreen ? 220 : 280),
                                      maxWidth: isVerySmallScreen ? 180 : (isSmallScreen ? 220 : 280),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            colors: [
                                              _getThemeColor().withOpacity(0.15),
                                              _getThemeColor().withOpacity(0.08),
                                              _getThemeColor().withOpacity(0.03),
                                              Colors.transparent,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: TreeWidget(
                                          session: _currentSession, 
                                          size: isVerySmallScreen ? 120 : (isSmallScreen ? 150 : 180)
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
                                
                                // 타이머 표시 (반응형)
                                Flexible(
                                  flex: 3,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: screenWidth * 0.8, // 화면 너비의 80%
                                      minHeight: isVerySmallScreen ? 60 : 80,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.06,
                                      vertical: isSmallScreen ? 12 : 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: _getThemeColor().withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getThemeColor().withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '$minutes:$seconds',
                                              style: TextStyle(
                                                fontSize: isVerySmallScreen ? 24 : (isSmallScreen ? 28 : 32),
                                                fontWeight: FontWeight.bold,
                                                color: _getThemeColor(),
                                                fontFeatures: const [FontFeature.tabularFigures()],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        if (!isVerySmallScreen) ...[
                                          SizedBox(height: isSmallScreen ? 4 : 8),
                                          Flexible(
                                            child: Text(
                                              _getMotivationalMessage(),
                                              style: TextStyle(
                                                fontSize: isSmallScreen ? 12 : 14,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 32)),
                          
                          // 테스트 버튼들 (디버그 모드에서만)
                          if (kDebugMode && !isVerySmallScreen) ...[
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bug_report,
                                        color: Colors.amber.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '개발자 테스트 모드',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber.shade800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: Icon(Icons.skip_next, size: isSmallScreen ? 16 : 20),
                                          label: Text(
                                            '1분 ⏭️',
                                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue.shade400,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _skipOneMinute,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: Icon(Icons.fast_forward, size: isSmallScreen ? 16 : 20),
                                          label: Text(
                                            '5분 ⚡',
                                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange.shade400,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _skipFiveMinutes,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 20),
                          ],
                          
                          // 포기하기 버튼
                          SizedBox(
                            width: double.infinity,
                            height: isVerySmallScreen ? 48 : (isSmallScreen ? 52 : 56),
                            child: _isAbandoning
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '처리 중...',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    icon: Icon(
                                      Icons.stop_circle_outlined,
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                    label: Text(
                                      '포기하기',
                                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade400,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: Colors.red.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.orange.shade600,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Text(
                                                  '정말 포기하시겠어요?',
                                                  style: TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: const Text(
                                            '지금 포기하면 나무가 시들게 됩니다.',
                                            style: TextStyle(height: 1.5),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: Text(
                                                '취소',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: Text(
                                                '포기',
                                                style: TextStyle(
                                                  color: Colors.red.shade600,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        _abandonFocusSession();
                                      }
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
} 