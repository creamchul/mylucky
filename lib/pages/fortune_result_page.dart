import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';

// Models imports
import '../models/models.dart';

import '../data/fortune_messages.dart';
import '../services/user_service.dart';
import '../services/reward_service.dart';

class FortuneResultPage extends StatefulWidget {
  final UserModel currentUser;
  
  const FortuneResultPage({super.key, required this.currentUser});

  @override
  State<FortuneResultPage> createState() => _FortuneResultPageState();
}

class _FortuneResultPageState extends State<FortuneResultPage>
    with TickerProviderStateMixin {
  bool _isCardFlipped = false;
  bool _isRevealing = true;
  bool _isTodayFortune = false; // 오늘 이미 뽑은 운세인지 확인
  bool _isSharing = false; // 공유 처리 중
  String _selectedFortune = '';
  
  // 사용자 모델 상태 관리
  late UserModel _currentUser; // late로 초기화 연기
  
  // 공유용 이미지 캡처를 위한 GlobalKey
  final GlobalKey _shareKey = GlobalKey();
  
  late AnimationController _flipController;
  late AnimationController _revealController;
  late Animation<double> _flipAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _currentUser = widget.currentUser; // 초기 사용자 모델 설정
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    ));
    
    _checkTodayFortune();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  // 오늘 날짜의 운세가 이미 있는지 확인하는 함수
  void _checkTodayFortune() async {
    if (kIsWeb) {
      final saved = await UserService.loadTodayFortuneWeb(userId: _currentUser.id);
      if (saved != null) {
        setState(() {
          _selectedFortune = saved;
          _isTodayFortune = true;
        });
        _showTodayFortune();
      } else {
        final fortune = FortuneMessages.getRandomMessage();
        await UserService.saveTodayFortuneWeb(userId: _currentUser.id, fortuneMessage: fortune);
        setState(() {
          _selectedFortune = fortune;
          _isTodayFortune = true;
        });
        _showTodayFortune();
        // 포인트 지급 등 추가 로직 필요시 여기에
      }
      return;
    }
    // 이하 기존 모바일/서버 로직 유지
    try {
      final fortuneResult = await UserService.handleTodayFortune(_currentUser.id);
      if (fortuneResult['hasFortuneToday'] == true) {
        _selectedFortune = fortuneResult['fortuneMessage'] as String;
        _isTodayFortune = true;
        if (kDebugMode) {
          print('오늘 이미 뽑은 운세를 발견했습니다: $_selectedFortune');
        }
        _showTodayFortune();
      } else {
        setState(() {
          _selectedFortune = FortuneMessages.getRandomMessage();
          _isTodayFortune = true;
        });
        _showTodayFortune();
        try {
          final rewardResult = await RewardService.giveFortuneReward(
            currentUser: _currentUser,
          );
          setState(() {
            _currentUser = rewardResult['user'] as UserModel;
          });
          final pointsEarned = rewardResult['pointsEarned'] as int;
          _showPointsEarnedSnackBar(pointsEarned, '운세');
        } catch (e) {
          if (kDebugMode) {
            print('운세 포인트 지급 실패: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('오늘 운세 확인 실패: $e');
      }
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

  // 오늘 이미 뽑은 운세를 표시하는 함수
  void _showTodayFortune() {
    setState(() {
      _isCardFlipped = true;
      _isRevealing = false;
    });
    
    _flipController.forward();
    _revealController.forward();
  }

  // 텍스트 공유 함수
  void _shareFortuneText() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final shareText = '✨ MyLucky에서 뽑은 오늘의 운세 ✨\n\n$_selectedFortune\n\n🍀 MyLucky 앱에서 당신만의 행운을 찾아보세요!';
      
      await Share.share(
        shareText,
        subject: 'MyLucky 오늘의 운세',
      );
    } catch (e) {
      if (kDebugMode) {
        print('텍스트 공유 실패: $e');
      }
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  // 이미지로 공유하는 함수
  void _shareFortuneImage() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // 위젯을 이미지로 캡처
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      // 이미지를 바이트 데이터로 변환
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final uint8List = byteData!.buffer.asUint8List();
      
      // 임시 파일로 저장
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/mylucky_fortune.png').create();
      await file.writeAsBytes(uint8List);
      
      // 공유
      final shareText = '✨ MyLucky에서 뽑은 오늘의 운세 ✨\n\n$_selectedFortune\n\n🍀 MyLucky 앱에서 당신만의 행운을 찾아보세요!';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'MyLucky 오늘의 운세',
      );
    } catch (e) {
      if (kDebugMode) {
        print('이미지 공유 실패: $e');
      }
      // 이미지 공유 실패 시 텍스트로 공유
      _shareFortuneText();
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        // 아무 동작도 하지 않음 (중복 pop 방지)
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context, _currentUser),
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.indigo.shade400,
              size: 20,
            ),
          ),
          title: Text(
            '오늘의 운세',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.indigo.shade400,
            ),
          ),
          centerTitle: true,
        ),
        body: RepaintBoundary(
          key: _shareKey,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFFAFAFA),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // 카드 애니메이션
                      Center(
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final isShowingFront = _flipAnimation.value < 0.5;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(_flipAnimation.value * 3.14159),
                              child: isShowingFront ? _buildCardFront() : _buildCardBack(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // 카드가 뒤집힌 후에만 운세 메시지, 포인트, 공유 버튼, 홈 버튼 표시
                      if (!_isRevealing && _isCardFlipped) ...[
                        // 공유 버튼
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _isSharing ? null : _shareFortuneImage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade400,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: Colors.blue.withOpacity(0.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isSharing
                                        ? SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.share,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '운세 공유하기',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
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
                        // 포인트 획득 정보 (오늘 처음 뽑은 경우에만)
                        if (!_isTodayFortune)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars,
                                  size: 16,
                                  color: Colors.amber.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '15 포인트 획득!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // 홈으로 돌아가기 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, _currentUser),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo.shade500,
                              side: BorderSide(color: Colors.indigo.shade200, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  '홈으로 돌아가기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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

  // 카드 앞면: 장식만, 문구 없음
  Widget _buildCardFront() {
    return Container(
      width: 240,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(
          color: Colors.indigo.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 장식적인 아이콘
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: Colors.indigo.shade500,
              ),
            ),
            const SizedBox(height: 8),
            // 카드 앞면에는 문구 없음
            Expanded(
              child: Center(
                child: Text(
                  '',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            // 하단 장식
            Container(
              width: 24,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.indigo.shade200,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카드 뒷면: 운세 문구만 표시
  Widget _buildCardBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159), // 좌우 반전 보정
      child: Container(
        width: 240,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade300,
              Colors.blue.shade400,
              Colors.teal.shade300,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 배경 패턴
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            // 중앙 운세 문구
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _selectedFortune,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 2,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // 모서리 장식
            Positioned(
              top: 12,
              left: 12,
              child: Icon(
                Icons.star,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Icon(
                Icons.star,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Icon(
                Icons.star,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Icon(
                Icons.star,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
