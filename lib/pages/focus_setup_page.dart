import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // CupertinoSlider 사용
import '../../models/user_model.dart'; // UserModel 필요
import '../../services/focus_service.dart';
import '../../models/focus_session_model.dart';
import './focusing_page.dart';

class FocusSetupPage extends StatefulWidget {
  final UserModel currentUser; // 현재 사용자 정보

  const FocusSetupPage({super.key, required this.currentUser});

  @override
  State<FocusSetupPage> createState() => _FocusSetupPageState();
}

class _FocusSetupPageState extends State<FocusSetupPage> with TickerProviderStateMixin {
  double _selectedDurationMinutes = 25.0; // 기본 25분
  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // TODO: 나무 종류 선택 UI (MVP에서는 기본 나무만 사용)
  // TreeType _selectedTreeType = TreeType.basic;

  void _startFocusSession() async {
    setState(() => _isLoading = true);
    try {
      final newSession = await FocusService.createSession(
        userId: widget.currentUser.id,
        durationMinutes: _selectedDurationMinutes.toInt(),
        // treeType: _selectedTreeType, // 추후 나무 선택 기능 추가 시
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FocusingPage(
              session: newSession,
              currentUser: widget.currentUser,
            ),
          ),
        );
      }
    } catch (e) {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('집중 세션 생성 실패: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getMotivationalMessage() {
    final duration = _selectedDurationMinutes.toInt();
    if (duration <= 15) {
      return '짧고 집중적인 시간이에요! 🚀';
    } else if (duration <= 30) {
      return '완벽한 집중 시간이에요! ⭐';
    } else if (duration <= 60) {
      return '깊은 집중의 시간이에요! 🎯';
    } else {
      return '도전적인 긴 집중이에요! 💪';
    }
  }

  Color _getThemeColor() {
    return Colors.teal.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _getThemeColor(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '집중하기 설정',
          style: TextStyle(
            color: _getThemeColor(),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더 섹션
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                          // 나무 아이콘과 제목
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getThemeColor().withOpacity(0.1),
                                  _getThemeColor().withOpacity(0.2),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.park_outlined,
                              size: 60,
                              color: _getThemeColor(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '나무와 함께 집중해요',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '설정한 시간 동안 집중하면\n아름다운 나무가 자라납니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 시간 설정 섹션
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getThemeColor().withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.timer_outlined,
                                size: 20,
                                color: _getThemeColor(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '집중 시간 설정',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 시간 표시
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getThemeColor().withOpacity(0.1),
                                  _getThemeColor().withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getThemeColor().withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_selectedDurationMinutes.toInt()}분',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: _getThemeColor(),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getMotivationalMessage(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 슬라이더
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _getThemeColor(),
                            inactiveTrackColor: _getThemeColor().withOpacity(0.2),
                            thumbColor: _getThemeColor(),
                            overlayColor: _getThemeColor().withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                          ),
                          child: Slider(
                            min: 10.0,
                            max: 120.0,
                            divisions: 11,
                            value: _selectedDurationMinutes,
                            onChanged: (double value) {
                              setState(() {
                                _selectedDurationMinutes = value.roundToDouble();
                              });
                            },
                          ),
                        ),
                        
                        // 슬라이더 라벨
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '10분',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '120분',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 시작 버튼
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getThemeColor().withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startFocusSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getThemeColor(),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '준비 중...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '집중 시작하기',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 팁 섹션
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '집중 팁',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• 휴대폰을 멀리 두고 시작하세요\n• 조용하고 편안한 환경을 만드세요\n• 집중 중에는 앱을 종료하지 마세요\n• 완료하면 포인트를 받을 수 있어요!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 