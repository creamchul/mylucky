import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Models imports
import '../models/models.dart';

// Services imports
import '../services/user_service.dart';
import '../services/challenge_service.dart';

class MyHistoryPage extends StatefulWidget {
  final UserModel currentUser;
  
  const MyHistoryPage({super.key, required this.currentUser});

  @override
  State<MyHistoryPage> createState() => _MyHistoryPageState();
}

class _MyHistoryPageState extends State<MyHistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late UserModel _currentUser;
  
  // 운세 기록
  List<FortuneModel> _fortuneHistory = [];
  bool _isLoadingFortunes = true;
  
  // 챌린지 기록
  List<UserChallenge> _challengeHistory = [];
  bool _isLoadingChallenges = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _currentUser = widget.currentUser;
    
    _tabController = TabController(length: 2, vsync: this);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadFortuneHistory();
    _loadChallengeHistory();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // 운세 기록을 불러오는 함수
  Future<void> _loadFortuneHistory() async {
    try {
      final history = await UserService.getUserFortuneHistory(_currentUser.id);

      setState(() {
        _fortuneHistory = history;
        _isLoadingFortunes = false;
      });

      if (kDebugMode) {
        print('운세 기록 로드 완료: ${history.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('운세 기록 로드 실패: $e');
      }
      setState(() {
        _isLoadingFortunes = false;
      });
    }
  }

  // 챌린지 기록을 불러오는 함수
  Future<void> _loadChallengeHistory() async {
    try {
      final history = await ChallengeService.getUserChallengeHistory(_currentUser.id);

      setState(() {
        _challengeHistory = history;
        _isLoadingChallenges = false;
      });

      if (kDebugMode) {
        print('챌린지 기록 로드 완료: ${history.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('챌린지 기록 로드 실패: $e');
      }
      setState(() {
        _isLoadingChallenges = false;
      });
    }
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
            color: Colors.indigo.shade400,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '내 기록',
          style: TextStyle(
            color: Colors.indigo.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo.shade600,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: Colors.indigo.shade500,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite, size: 18),
              text: '카드 기록',
            ),
            Tab(
              icon: Icon(Icons.emoji_events, size: 18),
              text: '챌린지 기록',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: TabBarView(
              controller: _tabController,
              children: [
                // 운세 기록 탭
                _buildFortuneHistoryTab(),
                // 챌린지 기록 탭
                _buildChallengeHistoryTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFortuneHistoryTab() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.indigo.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '카드 기록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Text(
              '지금까지 받으신 모든 카드를 확인하세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 운세 기록 리스트
            if (_isLoadingFortunes)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
              )
            else if (_fortuneHistory.isEmpty)
              _buildEmptyState(
                icon: Icons.favorite_outline,
                title: '아직 받은 카드가 없어요',
                subtitle: '첫 번째 카드를 받아보세요!',
                color: Colors.indigo,
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fortuneHistory.length,
                itemBuilder: (context, index) {
                  final fortune = _fortuneHistory[index];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.indigo.shade100,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 날짜와 시간
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.indigo.shade400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              fortune.formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.indigo.shade600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              fortune.formattedTime,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 카드 메시지
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.indigo.shade100,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            fortune.message,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeHistoryTab() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.orange.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '챌린지 기록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Text(
              '참여하신 모든 챌린지를 확인하세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 챌린지 기록 리스트
            if (_isLoadingChallenges)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              )
            else if (_challengeHistory.isEmpty)
              _buildEmptyState(
                icon: Icons.emoji_events_outlined,
                title: '아직 참여한 챌린지가 없어요',
                subtitle: '첫 번째 챌린지를 시작해보세요!',
                color: Colors.orange,
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _challengeHistory.length,
                itemBuilder: (context, index) {
                  final userChallenge = _challengeHistory[index];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getChallengeStatusColor(userChallenge).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더 (이모지, 제목, 상태)
                        Row(
                          children: [
                            Text(
                              userChallenge.challenge.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userChallenge.challenge.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${userChallenge.completedDays}/${userChallenge.challenge.durationDays}일 완료',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getChallengeStatusColor(userChallenge).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                userChallenge.status.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getChallengeStatusColor(userChallenge),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 진행률 바
                        LinearProgressIndicator(
                          value: userChallenge.progressPercentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getChallengeStatusColor(userChallenge),
                          ),
                          minHeight: 4,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 상세 정보
                        Row(
                          children: [
                            _buildChallengeInfoChip(
                              icon: Icons.calendar_today,
                              label: '시작: ${_formatDate(userChallenge.startDate)}',
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            if (userChallenge.endDate != null)
                              _buildChallengeInfoChip(
                                icon: Icons.event_available,
                                label: '완료: ${_formatDate(userChallenge.endDate!)}',
                                color: Colors.green.shade600,
                              ),
                            const Spacer(),
                            _buildChallengeInfoChip(
                              icon: Icons.stars,
                              label: '${userChallenge.totalPointsEarned}P',
                              color: Colors.amber.shade600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeInfoChip({
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
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getChallengeStatusColor(UserChallenge userChallenge) {
    switch (userChallenge.status) {
      case ChallengeStatus.completed:
        return Colors.green.shade600;
      case ChallengeStatus.inProgress:
        return Colors.blue.shade600;
      case ChallengeStatus.failed:
        return Colors.red.shade600;
      case ChallengeStatus.paused:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
            icon,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
} 