import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Models imports
import '../models/models.dart';

import '../services/user_service.dart';

// Pages imports
import 'my_history_page.dart';
import 'pet_care_page.dart';

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
  
  late UserModel _currentUser;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    _currentUser = widget.currentUser;
    
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
    
    _loadRankings();
    _loadUserStats();
    _fadeController.forward();
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
    if (state == AppLifecycleState.resumed) {
      // 앱이 다시 활성화될 때 데이터 새로고침
      _refreshAllData();
    }
  }

  // 모든 데이터 새로고침
  Future<void> _refreshAllData() async {
    setState(() {
      _isLoadingRankings = true;
      _isLoadingStats = true;
    });
    
    try {
      // 사용자 정보도 함께 새로고침
      final updatedUser = await UserService.getCurrentUser();
      if (updatedUser != null) {
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
    
    _loadRankings();
    _loadUserStats();
  }

  // 랭킹 데이터를 불러오는 함수
  Future<void> _loadRankings() async {
    try {
      final rankings = await UserService.getRankings();

      setState(() {
        _rankings = rankings;
        _isLoadingRankings = false;
      });

      if (kDebugMode) {
        print('랭킹 로드 완료: ${rankings.length}명');
      }
    } catch (e) {
      if (kDebugMode) {
        print('랭킹 로드 실패: $e');
      }
      setState(() {
        _isLoadingRankings = false;
      });
    }
  }

  // 사용자 통계를 불러오는 함수
  Future<void> _loadUserStats() async {
    try {
      final userStats = await UserService.getUserStats(_currentUser.id);
      
      setState(() {
        _userStats = userStats;
        _isLoadingStats = false;
      });

      if (kDebugMode) {
        print('사용자 통계 로드 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('사용자 통계 로드 실패: $e');
      }
      setState(() {
        _isLoadingStats = false;
      });
    }
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
        // 뒤로 가기 시 업데이트된 사용자 정보 반환
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
              // 뒤로 가기 시 업데이트된 사용자 정보 반환
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(_getPadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 내 통계 섹션
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.indigo.shade500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '내 통계',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo.shade600,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            if (_isLoadingStats)
                              const Center(
                                child: CircularProgressIndicator(),
                              )
                            else if (_userStats != null) ...[
                              // 통계 그리드
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: _getStatsCrossAxisCount(context),
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: _getStatsChildAspectRatio(context),
                                children: [
                                  _buildStatCard(
                                    '총 점수',
                                    '${_userStats!.score ?? 0}점',
                                    Icons.star,
                                    Colors.orange.shade300,
                                  ),
                                  _buildStatCard(
                                    '연속 출석',
                                    '${_userStats!.consecutiveDays ?? 0}일',
                                    Icons.calendar_today,
                                    Colors.green.shade300,
                                  ),
                                  _buildStatCard(
                                    '뽑은 운세',
                                    '${_userStats!.totalFortunes ?? 0}개',
                                    Icons.auto_awesome,
                                    Colors.indigo.shade300,
                                  ),
                                  _buildStatCard(
                                    '완료 미션',
                                    '${_userStats!.completedMissions ?? 0}개',
                                    Icons.check_circle,
                                    Colors.blue.shade300,
                                  ),
                                ],
                              ),
                            ] else
                              Center(
                                child: Text(
                                  '통계를 불러올 수 없습니다',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // 랭킹 섹션
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.leaderboard,
                                    size: 16,
                                    color: Colors.orange.shade500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '랭킹',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            if (_isLoadingRankings)
                              const Center(
                                child: CircularProgressIndicator(),
                              )
                            else if (_rankings.isNotEmpty) ...[
                              // 랭킹 리스트
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _rankings.length,
                                itemBuilder: (context, index) {
                                  final user = _rankings[index];
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: user.isTopThree
                                            ? Colors.orange.shade200 
                                            : Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // 순위 표시
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: user.isTopThree 
                                                ? Colors.orange.shade100 
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user.rankDisplay,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: user.isTopThree 
                                                  ? Colors.orange.shade700 
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        
                                        const SizedBox(width: 12),
                                        
                                        // 닉네임
                                        Expanded(
                                          child: Text(
                                            user.displayNickname,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ),
                                        
                                        // 점수와 연속 출석
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              user.formattedScore,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange.shade600,
                                              ),
                                            ),
                                            Text(
                                              user.formattedConsecutiveDays,
                                              style: TextStyle(
                                                fontSize: 10,
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
                            ] else
                              Center(
                                child: Text(
                                  '랭킹 정보를 불러올 수 없습니다',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // 메뉴 섹션
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.settings,
                                    size: 16,
                                    color: Colors.blue.shade500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '설정',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 메뉴 항목들
                            _buildMenuTile(
                              icon: Icons.history,
                              title: '내 기록',
                              subtitle: '운세 기록과 미션 기록',
                              color: Colors.indigo,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyHistoryPage(currentUser: _currentUser),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 8),
                            
                            _buildMenuTile(
                              icon: Icons.info_outline,
                              title: '앱 정보',
                              subtitle: '버전 정보 및 개발진',
                              color: Colors.purple,
                              onTap: _showAppInfoDialog,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            _buildMenuTile(
                              icon: Icons.refresh,
                              title: '데이터 새로고침',
                              subtitle: '랭킹 및 통계 업데이트',
                              color: Colors.green,
                              onTap: () async {
                                // 모든 데이터 새로고침 (사용자 정보 포함)
                                await _refreshAllData();
                                
                                // 새로고침 완료 알림
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('데이터가 새로고침되었습니다!'),
                                      backgroundColor: Colors.green.shade400,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            
                            const SizedBox(height: 8),
                            
                            _buildMenuTile(
                              icon: Icons.feedback_outlined,
                              title: '피드백 보내기',
                              subtitle: '개선사항이나 문의사항',
                              color: Colors.orange,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('피드백 기능은 곧 추가될 예정입니다!'),
                                    backgroundColor: Colors.orange.shade400,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
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
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 아이콘
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(height: 6),
          // 값
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 2),
          // 제목
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // 반응형 레이아웃을 위한 헬퍼 메서드들
  int _getStatsCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 4; // 태블릿에서는 4열
    } else if (screenWidth > 400) {
      return 2; // 일반적인 휴대폰
    } else {
      return 1; // 작은 화면
    }
  }

  double _getStatsChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getStatsCrossAxisCount(context);
    
    if (screenWidth > 600) {
      return 1.2; // 태블릿
    } else if (crossAxisCount == 1) {
      return 4.0; // 작은 화면에서는 가로로 넓게
    } else {
      return 2.8; // 일반적인 휴대폰
    }
  }

  double _getPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 20.0; // 태블릿
    } else if (screenWidth > 400) {
      return 16.0; // 일반적인 휴대폰
    } else {
      return 12.0; // 작은 화면
    }
  }
}
