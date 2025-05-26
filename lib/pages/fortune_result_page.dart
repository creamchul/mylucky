import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:io';

// Models imports
import '../models/models.dart';

import '../data/fortune_messages.dart';
import '../data/mission_data.dart';
import '../services/user_service.dart';

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
  bool _isMissionCompleted = false; // 오늘의 미션 완료 여부
  bool _isCheckingMission = false; // 미션 완료 처리 중
  bool _isSharing = false; // 공유 처리 중
  String _selectedFortune = '';
  String _todayMission = '';
  
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
    try {
      final fortuneResult = await UserService.handleTodayFortune(_currentUser.id);
      
      if (fortuneResult['hasFortuneToday'] == true) {
        // 오늘 이미 뽑은 운세가 있음
        _selectedFortune = fortuneResult['fortuneMessage'] as String;
        _todayMission = fortuneResult['todayMission'] as String;
        // 운세 모델 정보는 필요시 다른 방식으로 처리
        _isTodayFortune = true;
        
        // 미션이 비어있으면 생성
        if (_todayMission.isEmpty) {
          _todayMission = _generateTodayMission();
        }
        
        // 오늘의 미션 완료 여부 확인
        await _checkMissionStatus();
        
        if (kDebugMode) {
          print('오늘 이미 뽑은 운세를 발견했습니다: $_selectedFortune');
          print('오늘의 미션: $_todayMission');
        }
        
        _showTodayFortune();
      } else {
        // 오늘 아직 뽑지 않음
        _generateTodayMission();
        _startFortuneReveal();
      }
    } catch (e) {
      if (kDebugMode) {
        print('오늘 운세 확인 실패: $e');
      }
      // 오류 발생 시 새 운세 생성
      _generateTodayMission();
      _startFortuneReveal();
    }
  }

  // 오늘의 미션을 생성하는 함수 (날짜 기반으로 동일한 미션 보장)
  String _generateTodayMission() {
    final now = DateTime.now();
    _todayMission = MissionData.getTodayMission(now);
    return _todayMission;
  }

  // 오늘의 미션 완료 상태를 확인하는 함수
  Future<void> _checkMissionStatus() async {
    try {
      final isCompleted = await UserService.checkTodayMissionStatus(_currentUser.id);
      
      setState(() {
        _isMissionCompleted = isCompleted;
      });

      if (kDebugMode) {
        print('오늘의 미션 완료 상태: $_isMissionCompleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('미션 상태 확인 실패: $e');
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
      final result = await UserService.completeMission(
        currentUser: _currentUser,
        mission: _todayMission,
      );

      setState(() {
        _isMissionCompleted = true;
        _isCheckingMission = false;
        _currentUser = result['user'] as UserModel; // 업데이트된 사용자 모델
      });

      // 완료 피드백
      _showMissionCompletedDialog();

      if (kDebugMode) {
        print('미션 완료 처리 성공');
      }
    } catch (e) {
      setState(() {
        _isCheckingMission = false;
      });

      if (kDebugMode) {
        print('미션 완료 처리 실패: $e');
      }

      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('미션 완료 처리 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red.shade400,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green.shade500,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  '🎉 미션 완료!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  '오늘의 미션을 성공적으로 완료했습니다!\n작은 실천이 큰 변화를 만들어요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 오늘 이미 뽑은 운세를 바로 보여주는 함수
  void _showTodayFortune() async {
    // 짧은 대기 후 카드 뒤집기
    await Future.delayed(const Duration(milliseconds: 1000));
    
    await _flipController.forward();
    
    setState(() {
      _isCardFlipped = true;
      _isRevealing = false;
    });
    
    _revealController.forward();
  }

  void _startFortuneReveal() async {
    // 2초 후 카드 뒤집기 시작
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // 랜덤 운세 선택
    _selectedFortune = FortuneMessages.getRandomMessage();
    
    // 카드 뒤집기 애니메이션
    await _flipController.forward();
    
    setState(() {
      _isCardFlipped = true;
      _isRevealing = false;
    });
    
    // 결과 표시 애니메이션
    _revealController.forward();
    
    // 새로 뽑은 운세만 Firestore에 저장
    _saveToFirestore();
  }

  void _saveToFirestore() async {
    try {
      if (!kIsWeb && !_isTodayFortune) {
        final result = await UserService.saveNewFortune(
          currentUser: _currentUser,
          message: _selectedFortune,
          mission: _todayMission,
        );
        
        // 업데이트된 사용자 모델과 운세 모델 저장
        _currentUser = result['user'] as UserModel;
        
        if (kDebugMode) {
          print('새로운 운세 저장 완료: $_selectedFortune');
        }
      } else {
        if (kDebugMode) {
          if (kIsWeb) {
            print('웹 환경에서는 Firestore 저장을 스킵합니다');
          } else if (_isTodayFortune) {
            print('오늘 이미 뽑은 운세이므로 저장을 스킵합니다');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('운세 저장 실패: $e');
      }
    }
  }

  // 공유용 이미지 캡처 및 공유 함수
  Future<void> _shareFortuneImage() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // 위젯을 이미지로 캡처
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // 웹에서는 간단한 텍스트 공유
        await Share.share(
          '✨ MyLucky에서 뽑은 오늘의 운세 ✨\n\n$_selectedFortune\n\n🎯 오늘의 미션: $_todayMission\n\n🍀 MyLucky 앱에서 당신만의 행운을 찾아보세요!',
          subject: '오늘의 운세 - MyLucky',
        );
      } else {
        // 모바일에서는 이미지와 함께 공유
        final Directory tempDir = await getTemporaryDirectory();
        final File file = File('${tempDir.path}/mylucky_fortune_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: '✨ MyLucky에서 뽑은 오늘의 운세입니다! 🍀',
          subject: '오늘의 운세 - MyLucky',
        );
      }

      if (kDebugMode) {
        print('운세 이미지 공유 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('공유 실패: $e');
      }
      
      // 에러 발생 시 텍스트로만 공유
      try {
        await Share.share(
          '✨ MyLucky에서 뽑은 오늘의 운세 ✨\n\n$_selectedFortune\n\n🎯 오늘의 미션: $_todayMission\n\n🍀 MyLucky 앱에서 당신만의 행운을 찾아보세요!',
          subject: '오늘의 운세 - MyLucky',
        );
      } catch (shareError) {
        if (kDebugMode) {
          print('텍스트 공유도 실패: $shareError');
        }
      }
    } finally {
      setState(() {
        _isSharing = false;
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
          '운세 결과',
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
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          kToolbarHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 카드 영역
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 24),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final isShowingFront = _flipAnimation.value < 0.5;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(_flipAnimation.value * 3.14159),
                              child: isShowingFront
                                  ? _buildCardBack()
                                  : Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..rotateY(3.14159),
                                      child: _buildCardFront(),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                    // 오늘 뽑은 운세 표시
                    if (!_isRevealing && _isCardFlipped && _isTodayFortune)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.today,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '오늘 뽑으신 운세',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // 공유 버튼 (카드와 충분히 분리)
                    if (!_isRevealing && _isCardFlipped)
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
                    // 하단 버튼들
                    if (!_isRevealing) ...[
                      const SizedBox(height: 16),
                      // 다시 뽑기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isTodayFortune ? null : () {
                            _flipController.reset();
                            _revealController.reset();
                            setState(() {
                              _isCardFlipped = false;
                              _isRevealing = true;
                              _isTodayFortune = false;
                            });
                            _startFortuneReveal();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTodayFortune 
                                ? Colors.grey.shade300 
                                : Colors.indigo.shade300,
                            foregroundColor: Colors.white,
                            elevation: _isTodayFortune ? 0 : 2,
                            shadowColor: Colors.indigo.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isTodayFortune ? Icons.schedule : Icons.refresh, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _isTodayFortune ? '내일 다시 뽑기' : '다시 뽑기',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 홈으로 돌아가기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
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
    );
  }

  Widget _buildCardBack() {
    return Container(
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
          
          // 중앙 아이콘
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'MyLucky',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
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
    );
  }

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
            // 운세 메시지 - 카드 크기에 맞게 큼직하게
            Expanded(
              child: Center(
                child: Text(
                  _selectedFortune,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade600,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
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
}
