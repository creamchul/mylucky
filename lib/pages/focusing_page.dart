import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../models/focus_session_model.dart';
import '../../models/user_model.dart';
import '../models/focus_category_model.dart';
import '../services/category_service.dart';
import '../../services/focus_service.dart';
import '../../widgets/tree_widget.dart';
import 'home_page.dart'; // 같은 디렉토리의 home_page.dart 파일
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

class _FocusingPageState extends State<FocusingPage> with TickerProviderStateMixin {
  late FocusSessionModel _currentSession;
  Timer? _timer;
  bool _isAbandoning = false;
  
  FocusCategoryModel? _currentCategory;
  bool _isLoadingCategory = false;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    
    _loadCategoryInfo();
    
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // 타이머 모드: 남은 시간이 0이 되면 자동 완료
      if (!_currentSession.isStopwatchMode && _currentSession.remainingSeconds <= 0) {
        timer.cancel();
        _completeFocusSession();
      } else {
        // 스톱워치 모드는 무제한, 타이머 모드는 시간까지만
        setState(() {
          _currentSession = _currentSession.copyWith(
            elapsedSeconds: _currentSession.elapsedSeconds + 1,
          );
        });
        
        // 세션 업데이트를 주기적으로 저장 (매 10초마다)
        if (_currentSession.elapsedSeconds % 10 == 0) {
          FocusService.updateSession(_currentSession);
        }
      }
    });
  }

  Future<void> _completeFocusSession() async {
    try {
      setState(() {
        _currentSession = _currentSession.copyWith(
          status: FocusSessionStatus.completed,
          // 스톱워치 모드: 실제 경과 시간 유지, 타이머 모드: 설정된 시간으로 설정
          elapsedSeconds: _currentSession.isStopwatchMode 
              ? _currentSession.elapsedSeconds  // 스톱워치: 실제 경과 시간 유지
              : _currentSession.durationSecondsSet  // 타이머: 목표 시간으로 설정
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
                    ? _currentSession.isStopwatchMode 
                        ? '${_currentSession.formattedElapsedTime} 동안 집중하고\n나무를 성공적으로 키웠어요!'
                        : '${_currentSession.durationMinutesSet}분 집중을 완료하고\n나무를 성공적으로 키웠어요!'
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
                        _currentSession.isStopwatchMode
                            ? '+${_currentSession.stopwatchRewardPoints}P 적립!'
                            : '+${_currentSession.durationMinutesSet}P 적립!',
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
        elapsedSeconds: _currentSession.isStopwatchMode 
            ? newElapsedSeconds  // 스톱워치 모드: 제한 없이 증가
            : (newElapsedSeconds >= _currentSession.durationSecondsSet 
                ? _currentSession.durationSecondsSet 
                : newElapsedSeconds),
      );
    });
    
    FocusService.updateSession(_currentSession);
    
    // 타이머 모드에서만 자동 완료 체크
    if (!_currentSession.isStopwatchMode && _currentSession.remainingSeconds <= 0) {
      _timer?.cancel();
      _completeFocusSession();
    }
    
    if (kDebugMode) {
      print('테스트: 5분 앞당기기 - 현재 경과시간: ${_currentSession.formattedElapsedTime}');
    }
  }

  void _skipOneMinute() {
    if (!kDebugMode) return;
    
    setState(() {
      final newElapsedSeconds = _currentSession.elapsedSeconds + 60;
      _currentSession = _currentSession.copyWith(
        elapsedSeconds: _currentSession.isStopwatchMode 
            ? newElapsedSeconds  // 스톱워치 모드: 제한 없이 증가
            : (newElapsedSeconds >= _currentSession.durationSecondsSet 
                ? _currentSession.durationSecondsSet 
                : newElapsedSeconds),
      );
    });
    
    FocusService.updateSession(_currentSession);
    
    // 타이머 모드에서만 자동 완료 체크
    if (!_currentSession.isStopwatchMode && _currentSession.remainingSeconds <= 0) {
      _timer?.cancel();
      _completeFocusSession();
    }
    
    if (kDebugMode) {
      print('테스트: 1분 앞당기기 - 현재 경과시간: ${_currentSession.formattedElapsedTime}');
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

  // 카테고리 섹션 빌드
  Widget _buildCategorySection() {
    if (_isLoadingCategory) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '카테고리 정보 로딩 중...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_currentCategory == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade600,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '카테고리 정보를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _currentCategory!.color.withValues(alpha: 0.1),
            _currentCategory!.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentCategory!.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _currentCategory!.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _currentCategory!.icon,
              color: _currentCategory!.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentCategory!.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _currentCategory!.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentCategory!.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '집중 중',
                        style: TextStyle(
                          fontSize: 10,
                          color: _currentCategory!.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currentCategory!.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
                                // 현재 집중 카테고리 표시 (카테고리가 있는 경우에만)
                                if (_currentSession.categoryId != null) ...[
                                  _buildCategorySection(),
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                ],
                                
                                // 집중 모드 표시
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _currentSession.isStopwatchMode ? Icons.timer : Icons.timer_outlined,
                                      color: _getThemeColor(),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _currentSession.isStopwatchMode ? '스톱워치 모드' : '타이머 모드',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // 진행률 바
                                Container(
                                  width: double.infinity,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _currentSession.progress,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(_getThemeColor()),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // 진행률 텍스트
                                Text(
                                  '${(_currentSession.progress * 100).round()}% 완료',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 20 : 32),
                          
                          // 나무 위젯
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: _getThemeColor().withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: TreeWidget(
                              session: _currentSession,
                              size: isVerySmallScreen ? 180 : (isSmallScreen ? 220 : 260),
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 20 : 32),
                          
                          // 시간 표시
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 24 : 32,
                              vertical: isSmallScreen ? 20 : 24,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getThemeColor().withOpacity(0.1),
                                  _getThemeColor().withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getThemeColor().withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  timeDisplay,
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 36 : (isSmallScreen ? 42 : 48),
                                    fontWeight: FontWeight.bold,
                                    color: _getThemeColor(),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentSession.isStopwatchMode 
                                      ? '경과 시간'
                                      : '남은 시간',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!_currentSession.isStopwatchMode) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _getMotivationalMessage(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 24 : 32),
                          
                          // 포기 버튼
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 52 : 56,
                            child: ElevatedButton.icon(
                              onPressed: _isAbandoning ? null : () async {
                                final shouldAbandon = await _onWillPop();
                                if (shouldAbandon) {
                                  Navigator.of(context).pop();
                                }
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
                                  : const Icon(Icons.close, size: 20),
                              label: Text(
                                _isAbandoning ? '처리 중...' : '집중 포기',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: Colors.red.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _completeFocusSession,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '완료',
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