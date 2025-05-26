import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

// Models imports
import '../models/models.dart';

// Services imports
import '../services/pet_service.dart';
import '../services/reward_service.dart';
import '../services/user_service.dart';

class PetCarePage extends StatefulWidget {
  final UserModel currentUser;

  const PetCarePage({
    super.key,
    required this.currentUser,
  });

  @override
  State<PetCarePage> createState() => _PetCarePageState();
}

class _PetCarePageState extends State<PetCarePage> 
    with TickerProviderStateMixin {
  List<PetModel> _pets = [];
  bool _isLoading = true;
  late UserModel _currentUser;
  late AnimationController _floatingController;
  late AnimationController _heartController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _heartAnimation;
  
  // 렉 방지를 위한 상태 관리
  final Set<String> _processingPets = <String>{}; // 현재 처리 중인 펫 ID들
  bool _isProcessing = false; // 전체 처리 상태
  DateTime? _lastSnackBarTime; // 마지막 스낵바 표시 시간

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    
    // 애니메이션 컨트롤러 초기화
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 600), // 애니메이션 시간 단축
      vsync: this,
    );
    
    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.elasticOut,
    ));
    
    _floatingController.repeat(reverse: true);
    _loadUserPets();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  // 스낵바 표시 제한 함수
  void _showLimitedSnackBar(String message, Color backgroundColor) {
    final now = DateTime.now();
    if (_lastSnackBarTime != null && 
        now.difference(_lastSnackBarTime!).inMilliseconds < 1000) {
      return; // 1초 이내에는 스낵바를 표시하지 않음
    }
    
    _lastSnackBarTime = now;
    
    // 기존 스낵바 제거
    ScaffoldMessenger.of(context).clearSnackBars();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(milliseconds: 1500), // 표시 시간 단축
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 애니메이션 실행 제한 함수
  void _playHeartAnimation() {
    if (_heartController.isAnimating) return; // 이미 실행 중이면 무시
    
    _heartController.forward().then((_) {
      if (mounted) {
        _heartController.reset();
      }
    });
  }

  Future<void> _loadUserPets() async {
    try {
      final pets = await PetService.getUserPets(_currentUser.id);
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('펫 목록 로딩 실패: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAdoptionDialog() async {
    final availableAnimals = [
      {'type': AnimalType.cat, 'name': '고양이', 'emoji': '🐱'},
      {'type': AnimalType.dog, 'name': '강아지', 'emoji': '🐶'},
      {'type': AnimalType.rabbit, 'name': '토끼', 'emoji': '🐰'},
      {'type': AnimalType.hamster, 'name': '햄스터', 'emoji': '🐹'},
      {'type': AnimalType.bird, 'name': '새', 'emoji': '🐦'},
    ];
    
    await showDialog(
      context: context,
      builder: (context) => _AdoptionDialog(
        availableAnimals: availableAnimals,
        onAdopt: _adoptPet,
      ),
    );
  }

  Future<void> _adoptPet(AnimalType type, String name) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final result = await PetService.adoptPet(
        currentUser: _currentUser,
        name: name,
        animalType: type,
      );

      if (mounted) {
        setState(() {
          _pets.insert(0, result['pet']);
          _currentUser = result['user'];
          _isProcessing = false;
        });

        await UserService.updateUser(_currentUser);
        _showLimitedSnackBar('🎉 $name을(를) 입양했습니다!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showLimitedSnackBar('입양 실패: $e', Colors.red);
      }
    }
  }

  Future<void> _feedPet(PetModel pet) async {
    // 중복 요청 방지
    if (_processingPets.contains(pet.id) || _isProcessing) return;
    
    _processingPets.add(pet.id);
    
    try {
      final result = await PetService.feedPet(
        currentUser: _currentUser,
        pet: pet,
      );

      if (mounted) {
        setState(() {
          final index = _pets.indexWhere((p) => p.id == pet.id);
          if (index != -1) {
            _pets[index] = result['pet'];
          }
          _currentUser = result['user'];
        });

        await UserService.updateUser(_currentUser);
        _playHeartAnimation();
        _showLimitedSnackBar('🍽️ ${pet.name}이(가) 맛있게 먹었어요!', Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        _showLimitedSnackBar('먹이주기 실패: $e', Colors.red);
      }
    } finally {
      _processingPets.remove(pet.id);
    }
  }

  Future<void> _playWithPet(PetModel pet) async {
    // 중복 요청 방지
    if (_processingPets.contains(pet.id) || _isProcessing) return;
    
    _processingPets.add(pet.id);
    
    try {
      final result = await PetService.playWithPet(
        currentUser: _currentUser,
        pet: pet,
      );

      if (mounted) {
        setState(() {
          final index = _pets.indexWhere((p) => p.id == pet.id);
          if (index != -1) {
            _pets[index] = result['pet'];
          }
          _currentUser = result['user'];
        });

        await UserService.updateUser(_currentUser);
        _playHeartAnimation();
        _showLimitedSnackBar('🎾 ${pet.name}과(와) 즐겁게 놀았어요!', Colors.blue);
      }
    } catch (e) {
      if (mounted) {
        _showLimitedSnackBar('놀아주기 실패: $e', Colors.red);
      }
    } finally {
      _processingPets.remove(pet.id);
    }
  }

  Future<void> _levelUpPet(PetModel pet) async {
    // 중복 요청 방지
    if (_processingPets.contains(pet.id) || _isProcessing) return;
    
    _processingPets.add(pet.id);
    
    try {
      final result = await PetService.growPet(
        currentUser: _currentUser,
        pet: pet,
      );

      if (mounted) {
        setState(() {
          final index = _pets.indexWhere((p) => p.id == pet.id);
          if (index != -1) {
            _pets[index] = result['pet'];
          }
          _currentUser = result['user'];
        });

        await UserService.updateUser(_currentUser);
        _playHeartAnimation();
        _showLimitedSnackBar(
          '🎉 ${pet.name}이(가) ${result['pet'].stageDisplayName} 단계로 성장했어요!', 
          Colors.purple
        );
      }
    } catch (e) {
      if (mounted) {
        _showLimitedSnackBar('레벨업 실패: $e', Colors.red);
      }
    } finally {
      _processingPets.remove(pet.id);
    }
  }

  void _addTestPoints() {
    if (_isProcessing) return;
    
    setState(() {
      _currentUser = _currentUser.copyWith(
        rewardPoints: _currentUser.rewardPoints + 200, // 200포인트 추가
      );
    });
    
    UserService.updateUser(_currentUser);
    _showLimitedSnackBar('🎁 테스트용 포인트 200P가 추가되었습니다!', Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _currentUser);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F8F0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.green.shade400,
            ),
            onPressed: () => Navigator.pop(context, _currentUser),
          ),
          title: Row(
            children: [
              Icon(
                Icons.pets,
                color: Colors.green.shade400,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '동물 키우기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          actions: [
            // 테스트용 포인트 추가 버튼
            IconButton(
              onPressed: _addTestPoints,
              icon: Icon(
                Icons.add_circle,
                color: Colors.green.shade600,
                size: 20,
              ),
              tooltip: '테스트용 포인트 추가',
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_currentUser.rewardPoints}P',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAdoptionDialog,
          backgroundColor: Colors.green.shade400,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            '입양하기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ).animate().scale(delay: 300.ms),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_pets.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUserPets,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04, // 화면 너비의 4%
          vertical: 12,
        ),
        child: Column(
          children: [
            // 펫 목록
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pet = _pets[index];
                return _AnimatedPetCard(
                  pet: pet,
                  floatingAnimation: _floatingAnimation,
                  heartAnimation: _heartAnimation,
                  onFeed: () => _feedPet(pet),
                  onPlay: () => _playWithPet(pet),
                  onLevelUp: () => _levelUpPet(pet),
                  processingPets: _processingPets,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 60,
              color: Colors.green.shade300,
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 24),
          Text(
            '아직 키우고 있는 동물이 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          Text(
            '새로운 친구를 입양해서\n함께 행복한 시간을 보내보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}

// 애니메이션이 포함된 펫 카드
class _AnimatedPetCard extends StatefulWidget {
  final PetModel pet;
  final Animation<double> floatingAnimation;
  final Animation<double> heartAnimation;
  final VoidCallback onFeed;
  final VoidCallback onPlay;
  final VoidCallback onLevelUp;
  final Set<String> processingPets;

  const _AnimatedPetCard({
    required this.pet,
    required this.floatingAnimation,
    required this.heartAnimation,
    required this.onFeed,
    required this.onPlay,
    required this.onLevelUp,
    required this.processingPets,
  });

  @override
  State<_AnimatedPetCard> createState() => _AnimatedPetCardState();
}

class _AnimatedPetCardState extends State<_AnimatedPetCard>
    with TickerProviderStateMixin {
  late AnimationController _walkController;
  late AnimationController _breathController;
  late Animation<double> _walkAnimation;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    
    _walkController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _walkAnimation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _walkController,
      curve: Curves.easeInOut,
    ));
    
    _breathAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    ));
    
    // 애니메이션 시작
    _breathController.repeat(reverse: true);
    
    // 기분에 따른 애니메이션
    _startMoodBasedAnimations();
  }

  void _startMoodBasedAnimations() {
    switch (widget.pet.currentMood) {
      case AnimalMood.playful:
      case AnimalMood.excited:
        _walkController.repeat(reverse: true);
        break;
      default:
        _walkController.stop();
        break;
    }
  }

  @override
  void dispose() {
    _walkController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 반응형 크기 계산
    final cardPadding = screenWidth * 0.03; // 화면 너비의 3%
    final petAreaHeight = screenHeight * 0.15; // 화면 높이의 15%
    final spacing = screenHeight * 0.01; // 화면 높이의 1%
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 미니멀한 헤더 (이름과 레벨만)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    widget.pet.name,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045, // 반응형 폰트 크기
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: _getStageColor(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.pet.stageDisplayName} Lv.${widget.pet.level}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.025,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: spacing),
            
            // 심플한 펫 영역
            Container(
              height: petAreaHeight.clamp(100.0, 140.0), // 최소 100, 최대 140
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getPetBodyColor().withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  // 펫 애니메이션
                  Center(
                    child: _buildAnimatedPet(),
                  ),
                  
                  // 기분 표시 (우상단)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.015,
                        vertical: screenHeight * 0.002,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.pet.moodEmoji} ${widget.pet.moodDisplayName}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.022,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  // 하트 애니메이션 (위치 조정)
                  AnimatedBuilder(
                    animation: widget.heartAnimation,
                    builder: (context, child) {
                      if (widget.heartAnimation.value == 0) return const SizedBox();
                      
                      return Positioned(
                        top: 10,
                        left: 10,
                        child: Transform.scale(
                          scale: widget.heartAnimation.value,
                          child: Text(
                            '💖',
                            style: TextStyle(fontSize: screenWidth * 0.045),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            SizedBox(height: spacing),
            
            // 컴팩트한 상태 바
            _buildCompactStatusBars(),
            
            SizedBox(height: spacing),
            
            // 심플한 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    onPressed: widget.onFeed,
                    icon: Icons.restaurant,
                    label: '먹이',
                    color: Colors.orange.shade400,
                    isLoading: widget.processingPets.contains(widget.pet.id),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: _buildActionButton(
                    onPressed: widget.onPlay,
                    icon: Icons.sports_tennis,
                    label: '놀기',
                    color: Colors.blue.shade400,
                    isLoading: widget.processingPets.contains(widget.pet.id),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: _buildActionButton(
                    onPressed: _canLevelUp() ? widget.onLevelUp : null,
                    icon: Icons.trending_up,
                    label: '성장',
                    color: _canLevelUp() ? Colors.purple.shade400 : Colors.grey.shade400,
                    isLoading: widget.processingPets.contains(widget.pet.id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildAnimatedPet() {
    final screenWidth = MediaQuery.of(context).size.width;
    final petSize = (screenWidth * 0.18).clamp(60.0, 80.0); // 화면 너비의 18%, 최소 60, 최대 80
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.floatingAnimation,
        _walkAnimation,
        _breathAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _walkAnimation.value * 0.2, // 미묘한 좌우 움직임
            widget.floatingAnimation.value * 0.3, // 부유 효과
          ),
          child: Transform.scale(
            scale: _breathAnimation.value * 0.02 + 0.98, // 매우 미묘한 호흡
            child: Container(
              width: petSize,
              height: petSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getPetBodyColor().withOpacity(0.15),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getAnimalEmoji(),
                  style: TextStyle(
                    fontSize: _getEmojiSize(),
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

    Color _getPetBodyColor() {
    switch (widget.pet.animalType) {
      case AnimalType.cat:
        return Colors.orange.shade300;
      case AnimalType.dog:
        return Colors.brown.shade300;
      case AnimalType.rabbit:
        return Colors.grey.shade300;
      case AnimalType.hamster:
        return Colors.amber.shade300;
      case AnimalType.bird:
        return Colors.blue.shade300;
    }
  }

  String _getAnimalEmoji() {
    // 성장 단계와 동물 타입에 따른 이모지
    switch (widget.pet.animalType) {
      case AnimalType.cat:
        switch (widget.pet.stage) {
          case GrowthStage.baby:
            return '🐱';
          case GrowthStage.teen:
            return '🐈';
          case GrowthStage.adult:
            return '🐈‍⬛';
          case GrowthStage.master:
            return '🦁'; // 마스터는 사자로!
        }
      case AnimalType.dog:
        switch (widget.pet.stage) {
          case GrowthStage.baby:
            return '🐶';
          case GrowthStage.teen:
            return '🐕';
          case GrowthStage.adult:
            return '🐕‍🦺';
          case GrowthStage.master:
            return '🐺'; // 마스터는 늑대로!
        }
      case AnimalType.rabbit:
        switch (widget.pet.stage) {
          case GrowthStage.baby:
            return '🐰';
          case GrowthStage.teen:
            return '🐇';
          case GrowthStage.adult:
            return '🐇';
          case GrowthStage.master:
            return '🐰✨'; // 마스터는 반짝이는 토끼
        }
      case AnimalType.hamster:
        switch (widget.pet.stage) {
          case GrowthStage.baby:
            return '🐹';
          case GrowthStage.teen:
            return '🐹';
          case GrowthStage.adult:
            return '🐹';
          case GrowthStage.master:
            return '🐹👑'; // 마스터는 왕관 쓴 햄스터
        }
      case AnimalType.bird:
        switch (widget.pet.stage) {
          case GrowthStage.baby:
            return '🐣';
          case GrowthStage.teen:
            return '🐤';
          case GrowthStage.adult:
            return '🐦';
          case GrowthStage.master:
            return '🦅'; // 마스터는 독수리로!
        }
    }
  }

  String _getMoodEmoji() {
    switch (widget.pet.currentMood) {
      case AnimalMood.happy:
        return '😊';
      case AnimalMood.sleepy:
        return '😴';
      case AnimalMood.hungry:
        return '🍽️';
      case AnimalMood.playful:
        return '🎾';
      case AnimalMood.excited:
        return '🤩';
    }
  }

  double _getEmojiSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    double multiplier;
    
    switch (widget.pet.stage) {
      case GrowthStage.baby:
        multiplier = 0.08; // 화면 너비의 8%
        break;
      case GrowthStage.teen:
        multiplier = 0.09; // 화면 너비의 9%
        break;
      case GrowthStage.adult:
        multiplier = 0.10; // 화면 너비의 10%
        break;
      case GrowthStage.master:
        multiplier = 0.11; // 화면 너비의 11%
        break;
    }
    
    return (screenWidth * multiplier).clamp(28.0, 48.0); // 최소 28, 최대 48
  }

  Color _getStageColor() {
    switch (widget.pet.stage) {
      case GrowthStage.baby:
        return Colors.green.shade400;
      case GrowthStage.teen:
        return Colors.blue.shade400;
      case GrowthStage.adult:
        return Colors.orange.shade400;
      case GrowthStage.master:
        return Colors.purple.shade400;
    }
  }

  bool _canLevelUp() {
    // 마스터 단계면 더 이상 성장 불가
    if (widget.pet.stage == GrowthStage.master) {
      return false;
    }
    
    // 투자한 포인트가 성장 요구 포인트보다 많거나 같으면 성장 가능
    return widget.pet.totalPointsInvested >= widget.pet.growthRequiredPoints;
  }

  String _getLevelUpButtonText() {
    if (widget.pet.stage == GrowthStage.master) {
      return '최고 레벨';
    }
    
    final required = widget.pet.growthRequiredPoints;
    final invested = widget.pet.totalPointsInvested;
    
    if (invested >= required) {
      return '레벨업 가능!';
    } else {
      final needed = required - invested;
      return '성장까지 ${needed}P 더 필요';
    }
  }

  Widget _buildCompactStatusBars() {
    return Row(
      children: [
        Expanded(child: _buildCompactStatusBar('😊', widget.pet.happiness, Colors.pink)),
        const SizedBox(width: 8),
        Expanded(child: _buildCompactStatusBar('🍽️', 100 - widget.pet.hunger, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildCompactStatusBar('⚡', widget.pet.energy, Colors.blue)),
      ],
    );
  }

  Widget _buildCompactStatusBar(String emoji, int value, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: screenWidth * 0.035)),
        SizedBox(height: screenHeight * 0.003),
        Container(
          height: screenHeight * 0.006,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.002),
        Text(
          '$value%',
          style: TextStyle(
            fontSize: screenWidth * 0.022,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonHeight = (screenHeight * 0.055).clamp(40.0, 50.0); // 화면 높이의 5.5%, 최소 40, 최대 50
    
    return Container(
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? color.withOpacity(0.6) : color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: screenWidth * 0.035,
                height: screenWidth * 0.035,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: screenWidth * 0.035),
                  SizedBox(height: screenHeight * 0.002),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: screenWidth * 0.022,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusBars() {
    return Column(
      children: [
        _buildStatusBar('행복도', widget.pet.happiness, Colors.pink),
        const SizedBox(height: 8),
        _buildStatusBar('배고픔', 100 - widget.pet.hunger, Colors.orange),
        const SizedBox(height: 8),
        _buildStatusBar('에너지', widget.pet.energy, Colors.blue),
      ],
    );
  }

  Widget _buildStatusBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

// 입양 다이얼로그
class _AdoptionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableAnimals;
  final Function(AnimalType, String) onAdopt;

  const _AdoptionDialog({
    required this.availableAnimals,
    required this.onAdopt,
  });

  @override
  State<_AdoptionDialog> createState() => _AdoptionDialogState();
}

class _AdoptionDialogState extends State<_AdoptionDialog> {
  AnimalType? selectedType;
  String petName = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        '새로운 친구 입양하기',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '어떤 동물을 입양하시겠어요?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // 동물 선택
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.availableAnimals.map((animal) {
                final type = animal['type'] as AnimalType;
                final isSelected = selectedType == type;
                
                return GestureDetector(
                  onTap: () => setState(() => selectedType = type),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green.shade400 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          animal['emoji'],
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          animal['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            if (selectedType != null) ...[
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => setState(() => petName = value),
                decoration: InputDecoration(
                  hintText: '펫의 이름을 입력해주세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade400),
                  ),
                ),
                maxLength: 10,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: selectedType != null && petName.trim().isNotEmpty
              ? () {
                  Navigator.pop(context);
                  widget.onAdopt(selectedType!, petName.trim());
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('입양하기'),
        ),
      ],
    );
  }
} 