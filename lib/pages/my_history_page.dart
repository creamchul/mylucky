import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Models imports
import '../models/models.dart';

// Services imports
import '../services/user_service.dart';

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
  
  // 미션 기록
  List<MissionModel> _missionHistory = [];
  bool _isLoadingMissions = true;
  
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
    _loadMissionHistory();
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

  // 미션 기록을 불러오는 함수
  Future<void> _loadMissionHistory() async {
    try {
      final history = await UserService.getUserMissionHistory(_currentUser.id);

      setState(() {
        _missionHistory = history;
        _isLoadingMissions = false;
      });

      if (kDebugMode) {
        print('미션 기록 로드 완료: ${history.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('미션 기록 로드 실패: $e');
      }
      setState(() {
        _isLoadingMissions = false;
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
              icon: Icon(Icons.auto_awesome, size: 18),
              text: '운세 기록',
            ),
            Tab(
              icon: Icon(Icons.assignment, size: 18),
              text: '미션 기록',
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
                // 미션 기록 탭
                _buildMissionHistoryTab(),
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
                  Icons.auto_awesome,
                  color: Colors.indigo.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '운세 기록',
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
              '지금까지 뽑으신 모든 운세를 확인하세요',
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
                icon: Icons.auto_awesome_outlined,
                title: '아직 뽑은 운세가 없어요',
                subtitle: '첫 번째 운세를 뽑아보세요!',
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
                        
                        // 운세 메시지
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
                        
                        // 미션
                        if (fortune.mission.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 12,
                                color: Colors.orange.shade400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '오늘의 미션',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.shade100,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              fortune.mission,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildMissionHistoryTab() {
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
                  Icons.assignment,
                  color: Colors.orange.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '미션 기록',
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
              '완료하신 모든 미션을 확인하세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 미션 기록 리스트
            if (_isLoadingMissions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              )
            else if (_missionHistory.isEmpty)
              _buildEmptyState(
                icon: Icons.assignment_outlined,
                title: '아직 완료한 미션이 없어요',
                subtitle: '첫 번째 미션을 완료해보세요!',
                color: Colors.orange,
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
                        color: Colors.orange.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 완료 아이콘
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // 미션 내용과 날짜
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    mission.formattedDate,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.access_time,
                                    size: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    mission.formattedCompletedTime,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // 상대적 날짜
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mission.relativeDateString,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700,
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