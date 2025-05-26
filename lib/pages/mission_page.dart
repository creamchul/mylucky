import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Models imports
import '../models/models.dart';

// Data imports
import '../data/mission_data.dart';

// Services imports
import '../services/user_service.dart';

class MissionPage extends StatefulWidget {
  final UserModel currentUser;
  
  const MissionPage({super.key, required this.currentUser});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage>
    with TickerProviderStateMixin {
  String _todayMission = '';
  bool _isMissionCompleted = false;
  bool _isCheckingMission = false;
  bool _isLoading = true;
  List<MissionModel> _missionHistory = [];
  
  // 사용자 모델 상태 관리
  late UserModel _currentUser;
  
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _currentUser = widget.currentUser; // 초기 사용자 모델 설정
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadTodayMission();
    _checkMissionStatus();
    _loadMissionHistory();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // 오늘의 미션을 생성하는 함수
  void _loadTodayMission() {
    final now = DateTime.now();
    _todayMission = MissionData.getTodayMission(now);
    
    setState(() {
      _isLoading = false;
    });
    
    // 애니메이션 시작
    _fadeController.forward();
    _bounceController.forward();
    
    if (kDebugMode) {
      print('오늘의 미션: $_todayMission');
    }
  }

  // 오늘의 미션 완료 상태를 확인하는 함수
  Future<void> _checkMissionStatus() async {
    try {
      final isCompleted = await UserService.checkTodayMissionStatus(_currentUser.id);
      
      setState(() {
        _isMissionCompleted = isCompleted;
      });

      if (kDebugMode) {
        print('오늘의 미션 완료 상태: $_isMissionCompleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('미션 상태 확인 실패: $e');
      }
    }
  }

  // 미션 이력을 불러오는 함수
  Future<void> _loadMissionHistory() async {
    try {
      final history = await UserService.getUserMissionHistory(_currentUser.id);

      setState(() {
        _missionHistory = history;
      });

      if (kDebugMode) {
        print('미션 이력 로드 완료: ${history.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('미션 이력 로드 실패: $e');
      }
    }
  }

  // 미션 완료 처리 함수
  Future<void> _completeMission() async {
    if (_isMissionCompleted || _isCheckingMission) return;

    setState(() {
      _isCheckingMission = true;
    });

    try {
      final result = await UserService.completeMission(
        currentUser: _currentUser,
        mission: _todayMission,
      );

      setState(() {
        _isMissionCompleted = true;
        _isCheckingMission = false;
        _currentUser = result['user'] as UserModel; // 업데이트된 사용자 모델
      });

      // 미션 이력 새로고침
      _loadMissionHistory();
      
      if (mounted) {
        _showMissionCompletedDialog();
      }

      if (kDebugMode) {
        print('미션 완료 처리 성공');
      }
    } catch (e) {
      setState(() {
        _isCheckingMission = false;
      });

      if (kDebugMode) {
        print('미션 완료 처리 실패: $e');
      }

      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('미션 완료 처리 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  // 미션 완료 축하 다이얼로그
  void _showMissionCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 축하 아이콘
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green.shade600,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  '🎉 미션 완료!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  '오늘의 미션을 성공적으로 완료했습니다!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '작은 실천이 큰 변화를 만들어요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
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
              ],
            ),
          ),
        );
      },
    );
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
            color: Colors.orange.shade400,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '오늘의 미션',
          style: TextStyle(
            color: Colors.orange.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                )
              : SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 오늘의 미션 카드
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _bounceAnimation,
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.shade100,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // 미션 아이콘과 제목
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.assignment,
                                          size: 24,
                                          color: Colors.orange.shade500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '오늘의 미션',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateTime.now().toString().split(' ')[0],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // 미션 내용
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.shade100,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _todayMission,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // 완료 버튼
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isMissionCompleted ? null : (_isCheckingMission ? null : _completeMission),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isMissionCompleted 
                                            ? Colors.green.shade300 
                                            : Colors.orange.shade400,
                                        foregroundColor: Colors.white,
                                        elevation: _isMissionCompleted ? 1 : 2,
                                        shadowColor: _isMissionCompleted 
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: _isCheckingMission
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  _isMissionCompleted ? Icons.check_circle : Icons.play_arrow,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _isMissionCompleted ? '완료됨' : '미션 완료하기',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // 미션 이력 섹션
                        Text(
                          '최근 완료한 미션',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 미션 이력 리스트
                        if (_missionHistory.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '아직 완료한 미션이 없어요',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '첫 번째 미션을 완료해보세요!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _missionHistory.length,
                            itemBuilder: (context, index) {
                              final mission = _missionHistory[index];
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade100,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mission.mission,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${mission.formattedDate} ${mission.formattedCompletedTime} (${mission.relativeDateString})',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // 하단 설명
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 24,
                                color: Colors.blue.shade500,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '미션 팁',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '매일 작은 미션을 완료하면서 좋은 습관을 만들어보세요. 작은 변화가 모여 큰 성장을 만들어냅니다!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
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
