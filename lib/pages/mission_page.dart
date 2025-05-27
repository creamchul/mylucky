import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// Models imports
import '../models/models.dart';

// Data imports
import '../data/mission_data.dart';

// Services imports
import '../services/challenge_service.dart';

// Pages imports
import 'challenge_detail_page.dart';
import 'challenge_list_page.dart';

class MissionPage extends StatefulWidget {
  final UserModel currentUser;
  
  const MissionPage({super.key, required this.currentUser});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isLoading = true;
  
  // 챌린지 시스템
  List<UserChallenge> _activeChallenges = [];
  List<Challenge> _recommendedChallenges = [];
  Challenge? _todayRecommendedChallenge;
  bool _isLoadingChallenges = true;
  
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
    
    _loadChallengeData();
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
    
    // 앱이 다시 활성화될 때 챌린지 데이터 새로고침
    if (state == AppLifecycleState.resumed) {
      _loadChallengeData();
    }
  }



  // 챌린지 데이터 로딩
  Future<void> _loadChallengeData() async {
    try {
      // 활성 챌린지 로드
      final activeChallenges = await ChallengeService.getUserActiveChallenges(_currentUser.id);
      
      // 추천 챌린지 로드
      final recommendedChallenges = ChallengeService.getRecommendedChallenges(
        user: _currentUser,
        limit: 3,
      );
      
      // 오늘의 추천 챌린지
      final todayRecommended = ChallengeService.getTodayRecommendedChallenge();

      setState(() {
        _activeChallenges = activeChallenges;
        _recommendedChallenges = recommendedChallenges;
        _todayRecommendedChallenge = todayRecommended;
        _isLoading = false;
        _isLoadingChallenges = false;
      });

      // 애니메이션 시작
      _fadeController.forward();
      _bounceController.forward();

      if (kDebugMode) {
        print('챌린지 데이터 로드 완료: 활성 ${activeChallenges.length}개, 추천 ${recommendedChallenges.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('챌린지 데이터 로드 실패: $e');
      }
      setState(() {
        _isLoading = false;
        _isLoadingChallenges = false;
      });
    }
  }

  // 챌린지 완료 처리
  Future<void> _completeTodayChallenge(UserChallenge userChallenge) async {
    try {
      final result = await ChallengeService.completeTodayChallenge(
        currentUser: _currentUser,
        userChallenge: userChallenge,
      );

      setState(() {
        _currentUser = result['user'] as UserModel;
        // 활성 챌린지 목록에서 업데이트
        final index = _activeChallenges.indexWhere((c) => c.id == userChallenge.id);
        if (index != -1) {
          _activeChallenges[index] = result['userChallenge'] as UserChallenge;
        }
      });

      if (mounted) {
        _showPointsEarnedSnackBar(result['pointsEarned'] as int);
        
        // 챌린지 완료 시 축하 메시지
        if ((result['userChallenge'] as UserChallenge).isCompleted) {
          _showChallengeCompletedDialog(result['userChallenge'] as UserChallenge);
        }
      }

      if (kDebugMode) {
        print('챌린지 완료 처리 성공 - ${result['pointsEarned']}포인트 획득');
      }
    } catch (e) {
      if (kDebugMode) {
        print('챌린지 완료 처리 실패: $e');
      }

      if (mounted) {
        // 최적화된 에러 스낵바
        _showErrorSnackBar('챌린지 완료 처리 중 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }



  // 최적화된 포인트 획득 알림 표시
  void _showPointsEarnedSnackBar(int points) {
    if (!mounted) return;

    // 기존 스낵바 즉시 제거
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
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
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2), // 3초 → 2초로 단축
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),
    );
  }

  // 최적화된 에러 스낵바
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
      ),
    );
  }

  // 챌린지 완료 축하 다이얼로그
  void _showChallengeCompletedDialog(UserChallenge userChallenge) {
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
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.amber.shade600,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  '🎉 챌린지 완료!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  '${userChallenge.challenge.title} 챌린지를\n성공적으로 완료했습니다!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
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
                        '${userChallenge.challenge.pointsReward} 포인트 획득!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400,
                      foregroundColor: Colors.white,
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
          onPressed: () => Navigator.pop(context, _currentUser),
        ),
        title: Text(
          '챌린지',
          style: TextStyle(
            color: Colors.orange.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.list,
              color: Colors.orange.shade400,
            ),
            onPressed: () => _navigateToAllChallenges(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: SafeArea(
          child: _isLoading || _isLoadingChallenges
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
                        // 활성 챌린지 섹션
                        _buildSectionHeader('🔥 진행 중인 챌린지', _activeChallenges.isNotEmpty ? '${_activeChallenges.length}개' : ''),
                        const SizedBox(height: 12),
                        if (_activeChallenges.isNotEmpty) ...[
                          ..._activeChallenges.map((challenge) => _buildActiveChallengeCard(challenge)).toList(),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '진행 중인 챌린지가 없어요',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '아래에서 새로운 챌린지를 시작해보세요!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        
                        // 오늘의 추천 챌린지
                        if (_todayRecommendedChallenge != null) ...[
                          _buildSectionHeader('⭐ 오늘의 추천 챌린지', ''),
                          const SizedBox(height: 12),
                          _buildTodayRecommendedCard(_todayRecommendedChallenge!),
                          const SizedBox(height: 24),
                        ],
                        
                        // 추천 챌린지 섹션
                        if (_recommendedChallenges.isNotEmpty) ...[
                          _buildSectionHeader('💡 추천 챌린지', '나에게 맞는'),
                          const SizedBox(height: 12),
                          ..._recommendedChallenges.map((challenge) => _buildRecommendedChallengeCard(challenge)).toList(),
                          const SizedBox(height: 24),
                        ],
                        

                        
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
                                '챌린지 팁',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '꾸준한 챌린지 참여로 좋은 습관을 만들어보세요. 작은 변화가 모여 큰 성장을 만들어냅니다!',
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

  // 섹션 헤더 빌드
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }

  // 활성 챌린지 카드 빌드
  Widget _buildActiveChallengeCard(UserChallenge userChallenge) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                userChallenge.challenge.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userChallenge.challenge.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${userChallenge.completedDays}/${userChallenge.challenge.durationDays}일 완료',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${userChallenge.progressPercent}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 진행률 바
          LinearProgressIndicator(
            value: userChallenge.progressPercentage,
            backgroundColor: Colors.green.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
            minHeight: 6,
          ),
          
          const SizedBox(height: 12),
          
          // 오늘 완료 버튼
          if (userChallenge.canCompleteToday)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => _completeTodayChallenge(userChallenge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: userChallenge.isTodayCompleted 
                      ? Colors.green.shade300 
                      : Colors.green.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  userChallenge.isTodayCompleted ? '오늘 완료됨' : '오늘 완료하기',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (userChallenge.isCompleted)
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 18,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '챌린지 완료!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 오늘의 추천 챌린지 카드 빌드
  Widget _buildTodayRecommendedCard(Challenge challenge) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade100,
            Colors.blue.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToChallengeDetail(challenge),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        challenge.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.purple.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: '${challenge.durationDays}일',
                      color: Colors.purple.shade600,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.stars,
                      label: '${challenge.pointsReward}P',
                      color: Colors.amber.shade600,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '시작하기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 추천 챌린지 카드 빌드
  Widget _buildRecommendedChallengeCard(Challenge challenge) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _navigateToChallengeDetail(challenge),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  challenge.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.calendar_today,
                            label: '${challenge.durationDays}일',
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 6),
                          _buildInfoChip(
                            icon: Icons.stars,
                            label: '${challenge.pointsReward}P',
                            color: Colors.amber.shade600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 정보 칩 빌드
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 챌린지 상세 페이지로 이동
  Future<void> _navigateToChallengeDetail(Challenge challenge) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailPage(
          challenge: challenge,
          currentUser: _currentUser,
        ),
      ),
    );

    if (result != null && result is UserModel) {
      setState(() {
        _currentUser = result;
      });
      // 챌린지 데이터 새로고침
      _loadChallengeData();
    }
  }

  // 모든 챌린지 페이지로 이동
  Future<void> _navigateToAllChallenges() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeListPage(currentUser: _currentUser),
      ),
    );

    if (result != null && result is UserModel) {
      setState(() {
        _currentUser = result;
      });
      // 챌린지 데이터 새로고침
      _loadChallengeData();
    }
  }
}
