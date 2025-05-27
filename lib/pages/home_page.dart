import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Constants imports
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';

// Models imports
import '../models/models.dart';

// Services imports
import '../services/firebase_service.dart';
import '../services/user_service.dart';

// Pages imports
import 'fortune_result_page.dart';
import 'mission_page.dart';
import 'more_menu_page.dart';
import 'animal_clicker_page.dart';
import './focus_setup_page.dart';
import './my_forest_page.dart';
import 'my_history_page.dart';
import 'animal_collection_page.dart';
import 'my_stats_page.dart';
import 'ranking_page.dart';
// 아직 분리되지 않은 페이지들 - 임시로 main.dart에서 가져옴 (나중에 분리)
// import '../main.dart' show MoreMenuPage;

class MyLuckyHomePage extends StatefulWidget {
  const MyLuckyHomePage({super.key});

  @override
  State<MyLuckyHomePage> createState() => _MyLuckyHomePageState();
}

class _MyLuckyHomePageState extends State<MyLuckyHomePage> with WidgetsBindingObserver {
  int _consecutiveDays = 0;
  bool _isLoadingAttendance = true;
  bool _showCelebration = false;
  String _userNickname = '';
  String _userId = '';
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 앱이 다시 활성화될 때 사용자 정보 새로고침
      _refreshUserData();
    }
  }

  // 사용자 초기화 (닉네임 확인 및 생성)
  Future<void> _initializeUser() async {
    try {
      final userInfo = await UserService.initializeUser();
      
      _userId = userInfo['userId'];
      _userNickname = userInfo['nickname'];
      _currentUser = userInfo['user'] as UserModel?;

      if (userInfo['isNewUser'] == true) {
        // 새 사용자인 경우 닉네임 입력 요청
        await _showNicknameDialog();
      } else {
        // 기존 사용자인 경우 출석 체크
        _checkTodayAttendance();
      }
    } catch (e) {
      if (kDebugMode) {
        print('사용자 초기화 실패: $e');
      }
      _checkTodayAttendance();
    }
  }

  // 사용자 데이터 새로고침
  Future<void> _refreshUserData() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentUser = currentUser;
          _userNickname = currentUser.nickname;
        });
        
        if (kDebugMode) {
          print('홈 페이지: 사용자 정보 새로고침 완료 - ${currentUser.nickname}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('홈 페이지: 사용자 정보 새로고침 실패 - $e');
      }
    }
  }

  // 닉네임 입력 다이얼로그
  Future<void> _showNicknameDialog() async {
    String nickname = '';
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_add,
                color: AppColors.purple600,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.welcomeNewUser,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.nicknamePrompt,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                TextField(
                  onChanged: (value) => nickname = value,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: AppStrings.nicknameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.purple400),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nickname.trim().isEmpty) {
                    nickname = AppStrings.anonymous;
                  }
                  
                  // 먼저 다이얼로그를 닫고
                  Navigator.of(context).pop();
                  
                  // 그 다음에 사용자 생성
                  await _createNewUser(nickname.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(AppStrings.startButton),
              ),
            ),
          ],
        );
      },
    );
  }

  // 새 사용자 생성
  Future<void> _createNewUser(String nickname) async {
    try {
      _userNickname = nickname;
      
      final newUser = await UserService.createNewUser(
        userId: _userId,
        nickname: nickname,
      );
      
      _currentUser = newUser;

      if (kDebugMode) {
        print('새 사용자 생성: $nickname');
      }
      
      // 새 사용자 생성 후 출석 체크
      _checkTodayAttendance();
      
      // 약간의 지연 후 환영 보너스 알림 표시
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showWelcomeBonusDialog(nickname);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('사용자 생성 실패: $e');
      }
    }
  }

  // 오늘의 출석을 체크하고 연속 출석일수를 계산하는 함수
  Future<void> _checkTodayAttendance() async {
    if (_currentUser == null) {
      if (kDebugMode) {
        print('사용자 정보가 없어 출석 체크를 건너뜁니다.');
      }
      setState(() {
        _isLoadingAttendance = false;
      });
      return;
    }

    try {
      final attendanceResult = await UserService.checkAndUpdateAttendance(_currentUser!);
      
      final consecutiveDays = attendanceResult['consecutiveDays'] as int;
      final isFirstAttendanceToday = attendanceResult['isFirstAttendanceToday'] as bool;
      final shouldShowCelebration = attendanceResult['shouldShowCelebration'] as bool;
      final updatedUser = attendanceResult['user'] as UserModel;
      final pointsEarned = attendanceResult['pointsEarned'] as int? ?? 0;

      setState(() {
        _consecutiveDays = consecutiveDays;
        _isLoadingAttendance = false;
        _currentUser = updatedUser;
      });

      // 포인트 획득 알림 (첫 출석 시에만)
      if (isFirstAttendanceToday && pointsEarned > 0) {
        _showPointsEarnedSnackBar(pointsEarned, '출석');
      }

      // 축하 메시지 표시
      if (shouldShowCelebration) {
        setState(() {
          _showCelebration = true;
        });
        _showCelebrationDialog(consecutiveDays);
      }

    } catch (e) {
      if (kDebugMode) {
        print('출석 체크 실패: $e');
      }
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  // 최적화된 포인트 획득 알림 표시
  void _showPointsEarnedSnackBar(int points, String activity) {
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
                  '$activity으로 $points 포인트 획득!',
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

  // 축하 메시지 다이얼로그를 표시하는 함수
  void _showCelebrationDialog(int days) {
    String message = UserService.getCelebrationMessage(days);
    
    showDialog(
      context: context,
      barrierDismissible: false,
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
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.celebration,
                    size: 60,
                    color: Colors.orange.shade600,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  '🎉 축하합니다! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  '$days일 연속 출석 달성!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 포인트 알림 추가
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
                        '포인트를 획득했어요!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _showCelebration = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('고마워요!'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 환영 보너스 다이얼로그 표시
  void _showWelcomeBonusDialog(String nickname) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                // 환영 아이콘
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Colors.purple.shade600,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  '🎉 환영합니다! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  '$nickname님, MyLucky에 오신 것을 환영합니다!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  '감사의 의미로 특별한 선물을 준비했어요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 포인트 보너스 알림
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade300, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.stars,
                            color: Colors.amber.shade600,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '환영 보너스',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '100,000 포인트',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '지급 완료!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  '이 포인트로 귀여운 펫들을 키워보세요!\n매일 운세를 확인하고 미션을 완료하면\n더 많은 포인트를 얻을 수 있어요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    '시작하기',
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.indigo.shade400,
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.indigo.shade300,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'MyLucky',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // 포인트 표시
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars,
                  size: 14,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 3),
                Text(
                  '${_currentUser?.rewardPoints ?? 0}P',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA), // 연한 회색
              Color(0xFFF8F9FA), // 더 연한 회색
            ],
          ),
        ),
        child: SafeArea(
          child: _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildAttendanceCard(),
          const SizedBox(height: 16),
          
          _buildFocusButton(),
          _buildPetCareButton(),
          _buildFortuneButton(),
          _buildMissionButton(),
          const SizedBox(height: 24),
          
          Text(
            '✨ 활동할 때마다 포인트를 모아 새로운 친구들을 키워보세요 ✨',
            style: TextStyle(
              fontSize: 12,
              color: Colors.indigo.shade400,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Text(
          '안녕하세요, $_userNickname님!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          '오늘은 어떤 행운이 기다리고 있을까요?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAttendanceCard() {
    if (_isLoadingAttendance) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        child: CircularProgressIndicator(),
      ));
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade100,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 20,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                '연속 출석',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_consecutiveDays일',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneButton() {
    return Container(
      width: double.infinity,
      height: 88,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () async {
          if (_currentUser != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FortuneResultPage(currentUser: _currentUser!),
              ),
            );
            if (result != null && result is UserModel) {
              final refreshedUser = await UserService.getCurrentUser();
              setState(() {
                _currentUser = refreshedUser ?? result;
              });
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade300,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.indigo.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 28),
            SizedBox(height: 4),
            Text('오늘의 카드', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 1),
            Text('마음을 따뜻하게 하는 한 마디', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionButton() {
    return Container(
      width: double.infinity,
      height: 88,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () async {
          if (_currentUser != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MissionPage(currentUser: _currentUser!),
              ),
            );
             if (result != null && result is UserModel) {
              final refreshedUser = await UserService.getCurrentUser();
              setState(() {
                _currentUser = refreshedUser ?? result;
              });
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade300,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.orange.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 28),
            SizedBox(height: 4),
                            Text('챌린지', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 1),
            Text('꾸준한 도전으로 성장하기', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusButton() {
    return Container(
      width: double.infinity,
      height: 88,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () {
          if (_currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FocusSetupPage(currentUser: _currentUser!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade400,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.teal.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.park_outlined, size: 28),
            SizedBox(height: 4),
            Text('🌳 집중하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 1),
            Text('나무를 키우며 집중력을 높여보세요', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCareButton() {
    return Container(
      width: double.infinity,
      height: 88,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () async {
          if (_currentUser != null) {
            final updatedUser = await Navigator.push<UserModel>(
              context,
              MaterialPageRoute(
                                      builder: (context) => AnimalClickerPage(currentUser: _currentUser!),
              ),
            );
            if (updatedUser != null) {
              setState(() {
                _currentUser = updatedUser;
              });
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade300,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.pink.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 28),
            SizedBox(height: 4),
            Text('동물 친구들', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 1),
            Text('귀여운 동물들과 교감해보세요', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32.0, color: color),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // 사이드바 Drawer 빌드
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // 사용자 정보 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.indigo.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userNickname,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      '${_currentUser?.rewardPoints ?? 0} 포인트',
                      style: TextStyle(
                        fontSize: 14,
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
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: '내 통계',
                    subtitle: '점수, 출석, 활동 기록',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      if (_currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyStatsPage(currentUser: _currentUser!),
                          ),
                        );
                      }
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.leaderboard,
                    title: '랭킹',
                    subtitle: '다른 사용자들과 경쟁',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      if (_currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RankingPage(currentUser: _currentUser!),
                          ),
                        );
                      }
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.collections_bookmark,
                    title: '동물 도감',
                    subtitle: '수집한 동물 친구들',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      if (_currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnimalCollectionPage(currentUser: _currentUser!),
                          ),
                        );
                      }
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.forest_outlined,
                    title: '나의 숲',
                    subtitle: '내가 키운 나무들',
                    color: Colors.brown,
                    onTap: () {
                      Navigator.pop(context);
                      if (_currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyForestPage(currentUser: _currentUser!),
                          ),
                        );
                      }
                    },
                  ),
                  
                  _buildDrawerItem(
                    icon: Icons.history,
                    title: '내 기록',
                    subtitle: '카드 기록과 챌린지 기록',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      if (_currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyHistoryPage(currentUser: _currentUser!),
                          ),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 구분선
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: '앱 정보',
                    subtitle: '버전 정보 및 개발진',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _showAppInfoDialog();
                    },
                  ),
                ],
              ),
            ),
            
            // 하단 정보
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.purple.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MyLucky v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer 메뉴 아이템 빌드
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
}


