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
import 'pet_care_page.dart';
import './focus_setup_page.dart';
import './my_forest_page.dart';
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

  // 포인트 획득 알림 표시
  void _showPointsEarnedSnackBar(int points, String activity) {
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
                  '$activity으로 $points 포인트 획득!',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
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
        actions: [
          // 포인트 표시 추가
          Container(
            margin: const EdgeInsets.only(right: 8),
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
          IconButton(
            onPressed: () async {
              if (_currentUser != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MoreMenuPage(currentUser: _currentUser!),
                  ),
                );
                
                if (result != null && result is UserModel) {
                  await _refreshUserData();
                  await _checkTodayAttendance();
                }
              }
            },
            icon: Icon(
              Icons.menu,
              color: Colors.indigo.shade300,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
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
            Icon(Icons.auto_awesome, size: 28),
            SizedBox(height: 4),
            Text('오늘의 운세', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 1),
            Text('당신만을 위한 특별한 메시지', style: TextStyle(fontSize: 10, color: Colors.white70)),
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
            Icon(Icons.assignment, size: 28),
            SizedBox(height: 4),
            Text('오늘의 미션', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 1),
            Text('작은 실천으로 만드는 변화', style: TextStyle(fontSize: 10, color: Colors.white70)),
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
                builder: (context) => PetCarePage(currentUser: _currentUser!),
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
}


