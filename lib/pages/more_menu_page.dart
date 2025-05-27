import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Models imports
import '../models/models.dart';

import '../services/user_service.dart';

// Pages imports
import 'my_history_page.dart';
// import 'pet_care_page.dart'; // 제거됨 - 새로운 동물 콜렉터로 대체
import 'my_forest_page.dart';
import 'animal_collection_page.dart';

enum MenuSection {
  myStats,
  ranking,
  animalCollection,
  myForest,
  myHistory,
  appInfo,
}

class MoreMenuPage extends StatefulWidget {
  final UserModel currentUser;
  
  const MoreMenuPage({super.key, required this.currentUser});

  @override
  State<MoreMenuPage> createState() => _MoreMenuPageState();
}

class _MoreMenuPageState extends State<MoreMenuPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<RankingModel> _rankings = [];
  UserModel? _userStats;
  bool _isLoadingRankings = true;
  bool _isLoadingStats = true;
  bool _isRefreshing = false;
  
  late UserModel _currentUser;
  MenuSection _selectedSection = MenuSection.myStats;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    _currentUser = widget.currentUser;
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadRankings();
    _loadUserStats();
    _fadeController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted && !_isRefreshing) {
      _refreshAllData();
    }
  }

  // 모든 데이터 새로고침
  Future<void> _refreshAllData() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    
    if (mounted) {
      setState(() {
        _isLoadingRankings = true;
        _isLoadingStats = true;
      });
    }
    
    try {
      final updatedUser = await UserService.getCurrentUser();
      if (updatedUser != null && mounted) {
        setState(() {
          _currentUser = updatedUser;
        });
        
        if (kDebugMode) {
          print('더보기 페이지: 사용자 정보 새로고침 완료');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('더보기 페이지: 사용자 정보 새로고침 실패 - $e');
      }
    }
    
    await Future.wait([
      _loadRankings(),
      _loadUserStats(),
    ]);
    
    _isRefreshing = false;
  }

  // 랭킹 데이터를 불러오는 함수
  Future<void> _loadRankings() async {
    try {
      final rankings = await UserService.getRankings();

      if (mounted) {
        setState(() {
          _rankings = rankings;
          _isLoadingRankings = false;
        });
      }

      if (kDebugMode) {
        print('랭킹 로드 완료: ${rankings.length}명');
      }
    } catch (e) {
      if (kDebugMode) {
        print('랭킹 로드 실패: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingRankings = false;
        });
      }
    }
  }

  // 사용자 통계를 불러오는 함수
  Future<void> _loadUserStats() async {
    try {
      final userStats = await UserService.getUserStats(_currentUser.id);
      
      if (mounted) {
        setState(() {
          _userStats = userStats;
          _isLoadingStats = false;
        });
      }

      if (kDebugMode) {
        print('사용자 통계 로드 완료: ${userStats.nickname}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('사용자 통계 로드 실패: $e');
      }
      
      if (mounted) {
        setState(() {
          _userStats = UserModel.createNew(
            id: _currentUser.id, 
            nickname: _currentUser.nickname
          ).copyWith(
            totalFortunes: 0,
            totalMissions: 0,
            completedMissions: 0,
            consecutiveDays: 0,
            score: 0,
          );
          _isLoadingStats = false;
        });
      }
    }
  }

  // 메뉴 섹션 변경
  void _selectSection(MenuSection section) {
    setState(() {
      _selectedSection = section;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  // 앱 정보 다이얼로그
  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.purple.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'MyLucky',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '버전: 1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '개발자: 정준철',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MyLucky는 매일의 작은 행운을 발견하고, 긍정적인 습관을 만들어가는 앱입니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🍀 매일 새로운 운세를 확인하세요\n🎯 작은 미션으로 습관을 만들어보세요\n📊 다른 사용자들과 랭킹을 경쟁해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '확인',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _currentUser);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.indigo.shade400,
            ),
            onPressed: () {
              Navigator.pop(context, _currentUser);
            },
          ),
          title: Text(
            '더보기',
            style: TextStyle(
              color: Colors.indigo.shade500,
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
            child: Row(
              children: [
                // 사이드바
                _buildSidebar(),
                // 메인 콘텐츠
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 사이드바 빌드
  Widget _buildSidebar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.teal.shade50,
            Colors.blue.shade50,
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
                    child: Column(
                      children: [
          // 사용자 정보 헤더
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                              width: 1,
                ),
                            ),
                          ),
                          child: Column(
                                children: [
                                  Container(
                  padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                    size: 24,
                    color: Colors.indigo.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser.nickname,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentUser.rewardPoints}P',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 메뉴 항목들
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarItem(
                  icon: Icons.analytics,
                  title: '내 통계',
                  section: MenuSection.myStats,
                  color: Colors.indigo,
                ),
                _buildSidebarItem(
                  icon: Icons.leaderboard,
                  title: '랭킹',
                  section: MenuSection.ranking,
                  color: Colors.orange,
                ),
                _buildSidebarItem(
                  icon: Icons.collections_bookmark,
                  title: '동물 도감',
                  section: MenuSection.animalCollection,
                  color: Colors.green,
                ),
                _buildSidebarItem(
                  icon: Icons.forest_outlined,
                  title: '나의 숲',
                  section: MenuSection.myForest,
                  color: Colors.brown,
                ),
                _buildSidebarItem(
                  icon: Icons.history,
                  title: '내 기록',
                  section: MenuSection.myHistory,
                  color: Colors.purple,
                ),
                _buildSidebarItem(
                  icon: Icons.info_outline,
                  title: '앱 정보',
                  section: MenuSection.appInfo,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 사이드바 아이템 빌드
  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required MenuSection section,
    required Color color,
  }) {
    final isSelected = _selectedSection == section;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectSection(section),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? color : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 메인 콘텐츠 빌드
  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSelectedContent(),
      ),
    );
  }

  // 선택된 콘텐츠 빌드
  Widget _buildSelectedContent() {
    switch (_selectedSection) {
      case MenuSection.myStats:
        return _buildMyStatsContent();
      case MenuSection.ranking:
        return _buildRankingContent();
      case MenuSection.animalCollection:
        return _buildAnimalCollectionContent();
      case MenuSection.myForest:
        return _buildMyForestContent();
      case MenuSection.myHistory:
        return _buildMyHistoryContent();
      case MenuSection.appInfo:
        return _buildAppInfoContent();
    }
  }

  // 내 통계 콘텐츠
  Widget _buildMyStatsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics,
              color: Colors.indigo.shade500,
              size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '내 통계',
                                    style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade600,
                                    ),
                                  ),
                                ],
                              ),
        const SizedBox(height: 20),
                              
                              if (_isLoadingStats)
          const Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
                                  children: [
                                    _buildStatCard(
                                      '총 점수',
                                      '${_userStats?.score ?? 0}점',
                                      Icons.star,
                                      Colors.orange.shade300,
                                    ),
                                    _buildStatCard(
                                      '연속 출석',
                                      '${_userStats?.consecutiveDays ?? 0}일',
                                      Icons.calendar_today,
                                      Colors.green.shade300,
                                    ),
                                    _buildStatCard(
                  '받은 카드',
                                      '${_userStats?.totalFortunes ?? 0}개',
                  Icons.favorite,
                                      Colors.indigo.shade300,
                                    ),
                                    _buildStatCard(
                                      '완료 미션',
                                      '${_userStats?.completedMissions ?? 0}개',
                                      Icons.check_circle,
                                      Colors.blue.shade300,
                                    ),
                                  ],
                                          ),
                                        ),
                                      ],
    );
  }

  // 랭킹 콘텐츠
  Widget _buildRankingContent() {
    return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
            Icon(
                                      Icons.leaderboard,
                                      color: Colors.orange.shade500,
              size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '랭킹',
                                    style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
        const SizedBox(height: 20),
                              
                              if (_isLoadingRankings)
          const Center(child: CircularProgressIndicator())
        else if (_rankings.isNotEmpty)
          Expanded(
            child: ListView.builder(
                                  itemCount: _rankings.length,
                                  itemBuilder: (context, index) {
                                    final user = _rankings[index];
                                    
                                    return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: user.isTopThree
                                              ? Colors.orange.shade200 
                                              : Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: user.isTopThree 
                                                  ? Colors.orange.shade100 
                                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              user.rankDisplay,
                                              style: TextStyle(
                            fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: user.isTopThree 
                                                    ? Colors.orange.shade700 
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          
                      const SizedBox(width: 16),
                                          
                                          Expanded(
                                            child: Text(
                                              user.displayNickname,
                                              style: TextStyle(
                            fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ),
                                          
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                user.formattedScore,
                                                style: TextStyle(
                              fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange.shade600,
                                                ),
                                              ),
                                              Text(
                                                user.formattedConsecutiveDays,
                                                style: TextStyle(
                              fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
          )
        else
          const Center(
            child: Text('랭킹 정보를 불러올 수 없습니다'),
          ),
      ],
    );
  }

  // 동물 도감 콘텐츠
  Widget _buildAnimalCollectionContent() {
    return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
            Icon(
              Icons.collections_bookmark,
              color: Colors.green.shade500,
              size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
              '동물 도감',
                                    style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
        const SizedBox(height: 20),
        
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.collections_bookmark,
                  size: 64,
                  color: Colors.green.shade300,
                ),
                              const SizedBox(height: 16),
                Text(
                  '동물 도감을 확인하려면\n아래 버튼을 눌러주세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnimalCollectionPage(currentUser: _currentUser),
                                    ),
                                  );
                                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('동물 도감 보기'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 나의 숲 콘텐츠
  Widget _buildMyForestContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.forest_outlined,
              color: Colors.brown.shade500,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '나의 숲',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade600,
              ),
                              ),
                            ],
                          ),
        const SizedBox(height: 20),
        
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forest_outlined,
                  size: 64,
                  color: Colors.brown.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  '나의 숲을 확인하려면\n아래 버튼을 눌러주세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyForestPage(currentUser: _currentUser),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('나의 숲 보기'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 내 기록 콘텐츠
  Widget _buildMyHistoryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: Colors.purple.shade500,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '내 기록',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.purple.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  '카드 기록과 챌린지 기록을\n확인하려면 아래 버튼을 눌러주세요',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHistoryPage(currentUser: _currentUser),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('내 기록 보기'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 앱 정보 콘텐츠
  Widget _buildAppInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue.shade500,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              '앱 정보',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.purple.shade600,
                            size: 32,
            ),
            const SizedBox(width: 12),
                          Text(
                            'MyLucky',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildInfoRow('버전', '1.0.0'),
                      const SizedBox(height: 12),
                      _buildInfoRow('개발자', '정준철'),
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                              '앱 소개',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'MyLucky는 매일의 작은 행운을 발견하고, 긍정적인 습관을 만들어가는 앱입니다.',
                    style: TextStyle(
                      fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                  Text(
                              '주요 기능',
                    style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFeatureItem('🍀', '매일 새로운 운세를 확인하세요'),
                            _buildFeatureItem('🎯', '작은 미션으로 습관을 만들어보세요'),
                            _buildFeatureItem('📊', '다른 사용자들과 랭킹을 경쟁해보세요'),
                            _buildFeatureItem('🐾', '귀여운 동물들과 교감해보세요'),
                            _buildFeatureItem('🌳', '집중하며 나무를 키워보세요'),
                ],
              ),
            ),
                    ],
                  ),
            ),
          ],
        ),
      ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
