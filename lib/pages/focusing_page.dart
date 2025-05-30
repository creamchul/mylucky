import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/focus_session_model.dart';
import '../../models/user_model.dart';
import '../models/focus_category_model.dart';
import '../services/category_service.dart';
import '../../services/focus_service.dart';
import '../services/precision_timer_service.dart';
import '../services/session_recovery_service.dart';
import '../services/notification_service.dart';
import '../constants/app_colors.dart'; // 앱 색상 시스템 추가
import '../../widgets/tree_widget.dart';
import '../pages/home_page.dart'; // 경로 수정
import '../utils/snackbar_utils.dart';

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

class _FocusingPageState extends State<FocusingPage> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late FocusSessionModel _currentSession;
  final PrecisionTimerService _precisionTimer = PrecisionTimerService();
  bool _isAbandoning = false;
  bool _fiveMinuteNotificationSent = false;
  
  FocusCategoryModel? _currentCategory;
  bool _isLoadingCategory = false;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    
    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);
    
    _loadCategoryInfo();
    _initializeNotifications();
    
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
    
    _startPrecisionTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _precisionTimer.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        _precisionTimer.onAppPaused();
        SessionRecoveryService.updateLastActiveTime();
        if (kDebugMode) {
          print('앱 백그라운드 진입');
        }
        break;
      case AppLifecycleState.resumed:
        _precisionTimer.onAppResumed();
        if (kDebugMode) {
          print('앱 포그라운드 복귀');
        }
        break;
      default:
        break;
    }
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.initialize();
  }

  Future<void> _loadCategoryInfo() async {
    if (_currentSession.categoryId == null) return;
    
    setState(() => _isLoadingCategory = true);
    try {
      final category = await CategoryService.getCategoryById(_currentSession.categoryId!);
      if (mounted) {
        setState(() {
          _currentCategory = category;
          _isLoadingCategory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategory = false);
      }
      print('카테고리 정보 로딩 실패: $e');
    }
  }

  void _startPrecisionTimer() {
    final targetDuration = _currentSession.isStopwatchMode 
        ? null 
        : Duration(seconds: _currentSession.durationSecondsSet);
    
    _precisionTimer.start(
      duration: targetDuration,
      stopwatchMode: _currentSession.isStopwatchMode,
      onTickCallback: _onTimerTick,
      onCompleteCallback: _onTimerComplete,
    );
    
    // 진행률 애니메이션 시작
    if (!_currentSession.isStopwatchMode) {
      _progressController.forward();
    }
    
    if (kDebugMode) {
      print('정밀 타이머 시작: ${_currentSession.isStopwatchMode ? '스톱워치' : '타이머'} 모드');
    }
  }

  void _onTimerTick(Duration elapsed) {
    if (!mounted) return;
    
    setState(() {
      _currentSession = _currentSession.copyWith(
        elapsedSeconds: elapsed.inSeconds,
      );
    });
    
    // 세션 백업 (매 10초마다)
    if (elapsed.inSeconds % 10 == 0) {
      SessionRecoveryService.backupSession(_currentSession);
      FocusService.updateSession(_currentSession);
    }
    
    // 5분 남음 알림 (타이머 모드에서만)
    if (!_currentSession.isStopwatchMode && 
        !_fiveMinuteNotificationSent && 
        _currentSession.remainingSeconds <= 300 && 
        _currentSession.remainingSeconds > 295) {
      _fiveMinuteNotificationSent = true;
      NotificationService.showFiveMinutesLeftNotification();
    }
  }

  void _onTimerComplete() {
    if (!mounted) return;
    _completeFocusSession();
  }

  Future<void> _completeFocusSession() async {
    try {
      if (kDebugMode) {
        print('집중 세션 완료 처리 시작 - 모드: ${_currentSession.isStopwatchMode ? "스톱워치" : "타이머"}');
      }
      
      _precisionTimer.stop();
      
      setState(() {
        _currentSession = _currentSession.copyWith(
          status: FocusSessionStatus.completed,
          elapsedSeconds: _currentSession.isStopwatchMode 
              ? _currentSession.elapsedSeconds
              : _currentSession.durationSecondsSet,
        );
      });
      
      if (kDebugMode) {
        print('세션 상태 업데이트 완료 - 경과시간: ${_currentSession.elapsedSeconds}초');
      }
      
      final updatedSession = await FocusService.completeSession(_currentSession, widget.currentUser);
      
      if (kDebugMode) {
        print('FocusService.completeSession 완료');
      }
      
      // 세션 완료 알림
      final categoryName = _currentCategory?.name ?? '일반';
      if (_currentSession.isStopwatchMode) {
        await NotificationService.showStopwatchCompletedNotification(
          elapsedMinutes: _currentSession.elapsedSeconds ~/ 60,
          categoryName: categoryName,
        );
      } else {
        await NotificationService.showFocusCompletedNotification(
          durationMinutes: _currentSession.durationMinutesSet,
          categoryName: categoryName,
        );
      }
      
      // 휴식 시간 알림 (포모도로 기법)
      final breakMinutes = _currentSession.durationMinutesSet >= 25 ? 5 : 3;
      await NotificationService.showBreakTimeNotification(
        breakMinutes: breakMinutes,
      );
      
      // 활성 세션 제거
      await SessionRecoveryService.clearActiveSession();
      
      if (mounted) {
        setState(() => _currentSession = updatedSession);
        if (kDebugMode) {
          print('결과 다이얼로그 표시 시작');
        }
        _showResultDialog(true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('집중 세션 완료 처리 중 오류: $e');
      }
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
      _precisionTimer.stop();
      setState(() => _isAbandoning = true);
      
      final preAbandonedSession = _currentSession.copyWith(
        status: FocusSessionStatus.abandoned
      );
      setState(() {
        _currentSession = preAbandonedSession;
      });

      final updatedSession = await FocusService.abandonSession(preAbandonedSession);
      
      // 활성 세션 제거
      await SessionRecoveryService.clearActiveSession();
      
      // 모든 알림 취소
      await NotificationService.cancelAllNotifications();
      
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
        SnackBarUtils.showError(context, '집중 포기 처리 중 오류가 발생했습니다: $e');
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
            success ? '🎉 집중 성공! 🎉' : '😞 아쉽지만... 😞',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: success ? AppColors.focusMint : Colors.orange.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: success 
                      ? AppColors.focusMint.withOpacity(0.1) 
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: success 
                        ? AppColors.focusMint.withOpacity(0.3)
                        : Colors.orange.shade300,
                    width: 1.5,
                  ),
                ),
                child: TreeWidget(session: _currentSession, size: 120),
              ),
              const SizedBox(height: 20),
              Text(
                success
                    ? _currentSession.isStopwatchMode 
                        ? '🌱 ${_currentSession.formattedElapsedTime} 동안 집중하고\n나무를 성공적으로 키웠어요!'
                        : '🌱 ${_currentSession.durationMinutesSet}분 집중을 완료하고\n나무를 성공적으로 키웠어요!'
                    : '🍂 나무가 시들었어요.\n다음번엔 꼭 성공해봐요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (success) ...[
                const SizedBox(height: 12),
                Text(
                  _currentSession.isStopwatchMode 
                      ? '🌿 자유로운 집중이 열매를 맺었네요!'
                      : '🌿 목표한 시간을 모두 채웠어요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.focusMint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MyLuckyHomePage()),
                  (route) => false, // 모든 이전 라우트 제거
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '홈으로 돌아가기',
                style: TextStyle(
                  color: AppColors.focusMint,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    // 스톱워치 모드에서 10분 이상 경과한 경우 완료 처리
    if (_currentSession.isStopwatchMode && _currentSession.elapsedSeconds >= 600) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.focusMint.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.focusMint,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '집중을 완료하시겠어요?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '🌱 10분 이상 집중하셨네요! 훌륭해요!\n현재 상태의 나무를 받으실 수 있습니다.',
            style: TextStyle(
              height: 1.5,
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '계속 집중',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: AppColors.focusMint.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '완료하기',
                style: TextStyle(
                  color: AppColors.focusMint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        if (kDebugMode) {
          print('스톱워치 모드 - 10분 이상 경과 후 완료 처리 시작');
        }
        await _completeFocusSession();
        return false; // 페이지를 pop하지 않음 - 결과 다이얼로그에서 홈으로 이동
      }
      return false;
    }
    
    // 일반적인 포기 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '정말 포기하시겠어요?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _currentSession.isStopwatchMode 
              ? '🍂 10분 미만으로 집중하면 시든 나무를 받게 됩니다.\n계속 진행하시겠어요?'
              : '🍂 지금 포기하면 나무가 시들게 됩니다.\n계속 진행하시겠어요?',
          style: TextStyle(
            height: 1.5,
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: AppColors.focusMint.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              '계속 집중',
              style: TextStyle(
                color: AppColors.focusMint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
    
    // PrecisionTimer의 시작 시간을 5분 앞당김
    _precisionTimer.adjustStartTime(const Duration(minutes: 5));
    
    if (kDebugMode) {
      print('테스트: 5분 앞당기기 - 현재 경과시간: ${_currentSession.formattedElapsedTime}');
    }
  }

  void _skipOneMinute() {
    if (!kDebugMode) return;
    
    // PrecisionTimer의 시작 시간을 1분 앞당김
    _precisionTimer.adjustStartTime(const Duration(minutes: 1));
    
    if (kDebugMode) {
      print('테스트: 1분 앞당기기 - 현재 경과시간: ${_currentSession.formattedElapsedTime}');
    }
  }

  Color _getThemeColor() {
    return AppColors.focusMint;
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
      return '마지막 스퍼트! 🌵';
    }
  }

  // 통합된 상단 섹션 (카테고리만)
  Widget _buildCompactHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 현재 집중 카테고리 표시 (오른쪽) - 컴팩트 버전
        if (_currentSession.categoryId != null) 
          _buildCompactCategory(),
      ],
    );
  }

  // 컴팩트한 카테고리 표시
  Widget _buildCompactCategory() {
    if (_isLoadingCategory) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '로딩...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }
    
    if (_currentCategory == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            color: Colors.grey.shade500,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '카테고리 없음',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _currentCategory!.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _currentCategory!.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _currentCategory!.icon,
            color: _currentCategory!.color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _currentCategory!.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _currentCategory!.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 시간 표시 계산
    String timeDisplay;
    if (_currentSession.isStopwatchMode) {
      // 스톱워치 모드: 경과 시간 표시
      timeDisplay = _currentSession.formattedElapsedTime;
    } else {
      // 타이머 모드: 남은 시간 표시
      final minutes = (_currentSession.remainingSeconds / 60).floor().toString().padLeft(2, '0');
      final seconds = (_currentSession.remainingSeconds % 60).floor().toString().padLeft(2, '0');
      timeDisplay = '$minutes:$seconds';
    }
    
    // 반응형 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.focusMint.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.focusMint.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentSession.isStopwatchMode ? Icons.timer : Icons.timer_outlined,
                      color: AppColors.focusMint,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentSession.isStopwatchMode ? '스톱워치 모드' : '타이머 모드',
                      style: TextStyle(
                        color: AppColors.focusMint,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDFDFD),
                Color(0xFFF8F9FA),
                Color(0xFFF0F8F5),
                Color(0xFFFFF8F3),
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
                        horizontal: screenWidth * 0.06,
                        vertical: isVerySmallScreen ? 12 : 24,
                      ),
                      child: Column(
                        children: [
                          // 동기부여 메시지
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 20 : 24,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.focusMintLight.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.focusMint.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getMotivationalMessage(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: AppColors.focusMint,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          
                          // 나무 위젯
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            child: Center(
                              child: TreeWidget(
                                session: _currentSession,
                                size: isVerySmallScreen ? 180 : (isSmallScreen ? 220 : 260),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          
                          // 카테고리 (카테고리가 있을 때만 표시)
                          if (_currentSession.categoryId != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              child: Center(child: _buildCompactCategory()),
                            ),
                            
                            SizedBox(height: isSmallScreen ? 8 : 12),
                          ],
                          
                          // 시간 표시
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 20 : 24,
                              vertical: isSmallScreen ? 16 : 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.focusMint.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.focusMint.withOpacity(0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              timeDisplay,
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 42 : (isSmallScreen ? 48 : 54),
                                fontWeight: FontWeight.w900,
                                color: AppColors.focusMint,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 32 : 40),
                          
                          // 포기 버튼
                          Container(
                            width: double.infinity,
                            height: isSmallScreen ? 56 : 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isAbandoning ? null : () async {
                                await _onWillPop();
                              },
                              icon: _isAbandoning
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Icon(Icons.pause_circle_outline, size: 20, color: Colors.grey.shade600),
                              label: Text(
                                _isAbandoning ? '처리 중...' : '집중 그만하기',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                                foregroundColor: Colors.grey.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // 디버그 모드에서만 테스트 버튼들 표시
                          if (kDebugMode) ...[
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _skipOneMinute,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '+1분',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _skipFiveMinutes,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '+5분',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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