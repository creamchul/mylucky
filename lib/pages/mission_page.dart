import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models imports
import '../models/models.dart';

// Data imports
import '../data/mission_data.dart';

// Services imports
import '../services/user_service.dart';
import '../services/reward_service.dart';

class MissionPage extends StatefulWidget {
  final UserModel currentUser;
  
  const MissionPage({super.key, required this.currentUser});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
    
    // 앱 생명주기 관찰자 추가
    WidgetsBinding.instance.addObserver(this);
    
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
    WidgetsBinding.instance.removeObserver(this);
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 앱이 다시 활성화될 때 미션 상태 재확인
    if (state == AppLifecycleState.resumed) {
      _checkMissionStatus();
    }
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

  // 오늘의 미션 완료 상태를 로컬에 저장
  Future<void> _saveMissionCompletionStatus(bool isCompleted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'mission_completed_${today.year}_${today.month}_${today.day}_${_currentUser.id}';
      await prefs.setBool(todayKey, isCompleted);
      
      if (kDebugMode) {
        print('미션 완료 상태 저장: $todayKey = $isCompleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('미션 완료 상태 저장 실패: $e');
      }
    }
  }

  // 오늘의 미션 완료 상태를 로컬에서 불러오기
  Future<bool> _loadMissionCompletionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'mission_completed_${today.year}_${today.month}_${today.day}_${_currentUser.id}';
      final isCompleted = prefs.getBool(todayKey) ?? false;
      
      if (kDebugMode) {
        print('미션 완료 상태 로드: $todayKey = $isCompleted');
      }
      
      return isCompleted;
    } catch (e) {
      if (kDebugMode) {
        print('미션 완료 상태 로드 실패: $e');
      }
      return false;
    }
  }

  // 오늘의 미션 완료 상태를 확인하는 함수
  Future<void> _checkMissionStatus() async {
    try {
      // 먼저 로컬 저장소에서 확인
      bool isCompletedLocal = await _loadMissionCompletionStatus();
      
      // 서버에서도 확인 (웹이 아닌 경우)
      bool isCompletedServer = false;
      if (!kIsWeb) {
        try {
          isCompletedServer = await UserService.checkTodayMissionStatus(_currentUser.id);
        } catch (e) {
          if (kDebugMode) {
            print('서버 미션 상태 확인 실패: $e');
          }
        }
      }
      
      // 로컬 또는 서버 중 하나라도 완료되어 있으면 완료로 처리
      final isCompleted = isCompletedLocal || isCompletedServer;
      
      setState(() {
        _isMissionCompleted = isCompleted;
      });

      // 로컬과 서버 상태가 다르면 동기화
      if (isCompletedLocal != isCompletedServer) {
        await _saveMissionCompletionStatus(isCompleted);
      }

      if (kDebugMode) {
        print('오늘의 미션 완료 상태: 로컬=$isCompletedLocal, 서버=$isCompletedServer, 최종=$isCompleted');
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
      // 미션 완료 처리
      final result = await UserService.completeMission(
        currentUser: _currentUser,
        mission: _todayMission,
      );

      // 포인트 보상 지급
      final rewardResult = await RewardService.giveMissionReward(
        currentUser: result['user'] as UserModel,
      );

      setState(() {
        _isMissionCompleted = true;
        _isCheckingMission = false;
        _currentUser = rewardResult['user'] as UserModel; // 포인트가 반영된 사용자 모델
      });

      // 로컬 저장소에 완료 상태 저장
      await _saveMissionCompletionStatus(true);

      // 미션 이력 새로고침
      _loadMissionHistory();
      
      if (mounted) {
        // 포인트 획득 알림 표시
        _showPointsEarnedSnackBar(rewardResult['pointsEarned'] as int);
        
        // 완료 다이얼로그 표시
        _showMissionCompletedDialog();
      }

      if (kDebugMode) {
        print('미션 완료 처리 성공 - ${rewardResult['pointsEarned']}포인트 획득');
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

  // 포인트 획득 알림 표시
  void _showPointsEarnedSnackBar(int points) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.stars,
                color: Colors.amber.shade200,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '미션 완료로 $points 포인트 획득!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
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
                
                const SizedBox(height: 16),
                
                // 포인트 획득 알림 추가
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
                        '20 포인트 획득!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
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
