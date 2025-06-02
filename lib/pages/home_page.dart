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
import '../services/session_recovery_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';

// Pages imports
import 'fortune_result_page.dart';
import 'mission_page.dart';
import 'more_menu_page.dart';
import 'animal_clicker_page.dart';
import './focus_setup_page.dart';
import './focusing_page.dart';
import './my_forest_page.dart';
import 'my_history_page.dart';
import 'animal_collection_page.dart';
import 'my_stats_page.dart';
import 'ranking_page.dart';
import 'habit_dashboard_page.dart';
import 'todo_list_page.dart';
import 'mood_diary_page.dart';

import '../utils/snackbar_utils.dart';
import '../widgets/theme_toggle_widget.dart';

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
      _refreshUserData();
    }
  }

  // 사용자 초기화
  Future<void> _initializeUser() async {
    try {
      await NotificationService.initialize();
      
      final userInfo = await UserService.initializeUser();
      
      _userId = userInfo['userId'];
      _userNickname = userInfo['nickname'];
      _currentUser = userInfo['user'] as UserModel?;

      if (userInfo['isNewUser'] == true) {
        await _showNicknameDialog();
      } else {
        _checkTodayAttendance();
      }
      
      await _checkSessionRecovery();
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
          backgroundColor: Colors.white,
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
                  
                  Navigator.of(context).pop();
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

      _checkTodayAttendance();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showWelcomeBonusDialog();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('사용자 생성 실패: $e');
      }
    }
  }

  // 출석 체크
  Future<void> _checkTodayAttendance() async {
    if (_currentUser == null) {
      setState(() => _isLoadingAttendance = false);
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

      if (isFirstAttendanceToday && pointsEarned > 0) {
        _showPointsEarnedSnackBar(pointsEarned, '출석');
      }

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
      setState(() => _isLoadingAttendance = false);
    }
  }

  // 포인트 획득 알림
  void _showPointsEarnedSnackBar(int points, String activity) {
    if (mounted) {
      SnackBarUtils.showPointsEarned(context, points, activity);
    }
  }

  // 축하 메시지
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

  // 환영 보너스 다이얼로그
  void _showWelcomeBonusDialog() {
    final isDark = ThemeService().isDarkModeActive(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getPointColor(isDark).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.getPointColor(isDark).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.celebration,
                  size: 32,
                  color: AppColors.getPointColor(isDark),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MyLucky에 오신 것을 환영해요! 🎉',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                '감사의 의미로 특별한 선물을 준비했어요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getPointColor(isDark).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.getPointColor(isDark).withOpacity(0.3), width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stars,
                          color: AppColors.getPointColor(isDark),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '환영 보너스',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPointColor(isDark),
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
                        color: AppColors.getPointColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '지급 완료!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getPointColor(isDark),
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getCardColor(isDark),
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
        );
      },
    );
  }

  // 앱 정보 다이얼로그
  void _showAppInfoDialog() {
    final isDark = ThemeService().isDarkModeActive(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.getCardColor(isDark),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'MyLucky',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getCardColor(isDark),
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '개발자: 정준철',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MyLucky는 매일의 작은 행운을 발견하고, 긍정적인 습관을 만들어가는 앱입니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🍀 매일 새로운 운세를 확인하세요\n🎯 작은 미션으로 습관을 만들어보세요\n📊 다른 사용자들과 랭킹을 경쟁해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                  color: AppColors.getCardColor(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 세션 복구 확인
  Future<void> _checkSessionRecovery() async {
    if (_currentUser == null) return;
    
    try {
      final activeSession = await SessionRecoveryService.checkActiveSession();
      if (activeSession != null && mounted) {
        final shouldRecover = await SessionRecoveryService.showRecoveryDialog(
          context, 
          activeSession
        );
        
        if (shouldRecover) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FocusingPage(
                session: activeSession,
                currentUser: _currentUser!,
              ),
            ),
          );
        } else {
          await SessionRecoveryService.clearActiveSession();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('세션 복구 확인 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppColors.getCardColor(ThemeService().isDarkModeActive(context)),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'MyLucky',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // 다크모드 토글 버튼
          SimpleThemeToggle(size: 20),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars,
                  color: Colors.amber.shade600,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentUser?.rewardPoints ?? 0}',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.getHomeGradient(
              ThemeService().isDarkModeActive(context)
            ),
          ),
        ),
        child: _buildMainContent(),
      ),
      drawer: _buildDrawer(),
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
          _buildMoodDiaryButton(),
          _buildFortuneButton(),
          _buildTodoButton(),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '✨ 매일의 작은 노력이 모여 큰 변화를 만들어요 ✨',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Text(
          '안녕하세요, $_userNickname님! 🌟',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '오늘도 작은 변화로 더 나은 하루를 만들어가요',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
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
    
    final isDark = ThemeService().isDarkModeActive(context);
    final attendanceColor = AppColors.getAttendanceColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkCardBackground 
            : AppColors.attendanceGreenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: attendanceColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: attendanceColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: attendanceColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              size: 24,
              color: attendanceColor,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                '연속 출석',
                style: TextStyle(
                  fontSize: 13,
                  color: attendanceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$_consecutiveDays일째',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: attendanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusButton() {
    final isDark = ThemeService().isDarkModeActive(context);
    final focusColor = AppColors.getFocusColor(isDark);
    
    return Container(
      width: double.infinity,
      height: 92,
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
          backgroundColor: focusColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: focusColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, size: 32),
            SizedBox(height: 6),
            Text('집중하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('오늘도 함께 성장하는 나무 한 그루', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCareButton() {
    final isDark = ThemeService().isDarkModeActive(context);
    final petColor = AppColors.getPetColor(isDark);
    
    return Container(
      width: double.infinity,
      height: 92,
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
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: petColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: petColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 32),
            SizedBox(height: 6),
            Text('펫 케어', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('작은 친구들이 당신을 기다리고 있어요', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDiaryButton() {
    final isDark = ThemeService().isDarkModeActive(context);
    final moodColor = AppColors.getPrimaryPink(isDark);
    
    return Container(
      width: double.infinity,
      height: 92,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () async {
          if (_currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MoodDiaryPage(currentUser: _currentUser!),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: moodColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: moodColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, size: 32),
            SizedBox(height: 6),
            Text('감정일기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('소중한 감정과 활동을 기록하세요', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneButton() {
    final isDark = ThemeService().isDarkModeActive(context);
    final cardColor = AppColors.getCardColor(isDark);
    
    return Container(
      width: double.infinity,
      height: 92,
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
          backgroundColor: cardColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: cardColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 32),
            SizedBox(height: 6),
            Text('오늘의 카드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('오늘의 따뜻한 메시지를 받아보세요', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoButton() {
    final isDark = ThemeService().isDarkModeActive(context);
    final routineColor = AppColors.getRoutineColor(isDark);
    
    return Container(
      width: double.infinity,
      height: 92,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () async {
          if (_currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TodoListPage(currentUser: _currentUser!),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: routineColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: routineColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 32),
            SizedBox(height: 6),
            Text('오늘의 루틴', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text('작은 실천이 만드는 변화', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  // 새로운 톤앤매너에 맞춘 드로어
  Widget _buildDrawer() {
    final isDark = ThemeService().isDarkModeActive(context);
    
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.getHomeGradient(isDark),
          ),
        ),
        child: Column(
          children: [
            // 사용자 정보 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.getCardColor(isDark).withOpacity(0.8),
                          AppColors.getCardColor(isDark),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userNickname,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.getPointColor(isDark).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.getPointColor(isDark).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars,
                          color: AppColors.getPointColor(isDark),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentUser?.rewardPoints ?? 0} 포인트',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getPointColor(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 메뉴 항목들
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: '내 통계',
                    subtitle: '점수, 출석, 활동 기록을 확인해보세요',
                    color: AppColors.getFocusColor(isDark),
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
                    subtitle: '다른 사용자들과 순위를 경쟁해보세요',
                    color: AppColors.getPetColor(isDark),
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
                    subtitle: '수집한 귀여운 동물 친구들을 만나보세요',
                    color: AppColors.getAttendanceColor(isDark),
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
                    title: '집중 통계',
                    subtitle: '나의 집중 여정과 성장을 살펴보세요',
                    color: AppColors.getFocusColor(isDark),
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
                    subtitle: '소중한 추억들을 다시 만나보세요',
                    color: AppColors.getCardColor(isDark),
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
                  
                  const SizedBox(height: 20),
                  
                  // 구분선
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.shade300,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: '앱 정보',
                    subtitle: '버전 정보와 개발진을 확인해보세요',
                    color: AppColors.getRoutineColor(isDark),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppColors.getCardColor(isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MyLucky v1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  // 새로운 톤앤매너의 드로어 아이템
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeService().isDarkModeActive(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkCardBackground.withOpacity(0.8) 
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
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
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 