import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/animal_collector_service.dart';
import '../data/animal_data.dart';
import 'animal_collection_page.dart';
import '../utils/snackbar_utils.dart';
import '../constants/app_colors.dart';

class AnimalClickerPage extends StatefulWidget {
  final UserModel currentUser;

  const AnimalClickerPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<AnimalClickerPage> createState() => _AnimalClickerPageState();
}

class _AnimalClickerPageState extends State<AnimalClickerPage>
    with TickerProviderStateMixin {
  UserModel? _currentUser;
  CurrentPet? _currentPet;
  AnimalSpecies? _currentSpecies;
  bool _isLoading = true;
  bool _canUseFreeGacha = false;
  
  // 애니메이션 컨트롤러들
  late AnimationController _petAnimationController;
  late AnimationController _clickAnimationController;
  late Animation<double> _petScaleAnimation;
  late Animation<double> _clickScaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    
    // 애니메이션 초기화
    _petAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _clickAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _petScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _petAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _clickScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _clickAnimationController,
      curve: Curves.elasticOut,
    ));
    
    // 반복 애니메이션 시작
    _petAnimationController.repeat(reverse: true);
    
    _loadData();
  }

  @override
  void dispose() {
    _petAnimationController.dispose();
    _clickAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // 현재 키우는 동물 로드
      final currentPet = await AnimalCollectorService.getCurrentPet(_currentUser!.id);
      
      // 무료 뽑기 가능 여부 확인
      final canFree = await AnimalCollectorService.canUseFreeGacha(_currentUser!.id);
      
      // 현재 동물의 종족 정보 가져오기
      AnimalSpecies? species;
      if (currentPet != null) {
        species = AnimalData.getSpeciesById(currentPet.speciesId);
      }
      
      setState(() {
        _currentPet = currentPet;
        _currentSpecies = species;
        _canUseFreeGacha = canFree;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('AnimalClickerPage: 데이터 로드 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnimalClickerPage: 데이터 로드 실패 - $e');
      }
      setState(() => _isLoading = false);
    }
  }

  // 뽑기 실행
  Future<void> _performGacha({bool isFree = false}) async {
    try {
      final result = await AnimalCollectorService.performGacha(
        userId: _currentUser!.id,
        currentUser: _currentUser!,
        isFree: isFree,
      );
      
      if (result['success']) {
        setState(() {
          _currentUser = result['user'];
          _currentPet = result['pet'];
          _currentSpecies = result['species'];
          _canUseFreeGacha = false;
        });
        
        // 뽑기 결과 다이얼로그 표시
        _showGachaResultDialog(result);
      } else {
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      _showErrorSnackBar('뽑기 중 오류가 발생했습니다: $e');
    }
  }

  // 동물 클릭 (클릭커 게임의 핵심)
  Future<void> _clickPet() async {
    if (_currentPet == null) return;
    
    try {
      // 클릭 애니메이션 실행
      _clickAnimationController.forward().then((_) {
        _clickAnimationController.reverse();
      });
      
      final result = await AnimalCollectorService.clickPet(_currentUser!.id, currentUser: _currentUser);
      if (result['success']) {
        setState(() {
          _currentPet = result['pet'];
          // 유저 정보 업데이트 (레벨업 포인트 보상 적용)
          if (result['user'] != null) {
            _currentUser = result['user'];
          }
        });
        
        // 특별 메시지 표시
        if (result['specialMessage'] != null) {
          _showSuccessSnackBar(result['specialMessage']);
        }
        
        // 레벨업 메시지들 순차 표시
        if (result['leveledUp'] && result['levelUpMessages'] != null) {
          final messages = result['levelUpMessages'] as List<String>;
          for (int i = 0; i < messages.length; i++) {
            Future.delayed(Duration(milliseconds: i * 1000), () {
              _showSuccessSnackBar(messages[i]);
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnimalClickerPage: 클릭 처리 실패 - $e');
      }
    }
  }

  // 업그레이드 구매
  Future<void> _purchaseUpgrade(String upgradeType) async {
    if (_currentPet == null || _currentUser == null) return;
    
    try {
      final result = await AnimalCollectorService.purchaseUpgrade(
        userId: _currentUser!.id,
        currentUser: _currentUser!,
        upgradeType: upgradeType,
      );
      
      if (result['success']) {
        setState(() {
          _currentUser = result['user'];
          _currentPet = result['pet'];
        });
        
        _showSuccessSnackBar('업그레이드 완료! (-${result['cost']}P)');
      } else {
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      _showErrorSnackBar('업그레이드 중 오류가 발생했습니다: $e');
    }
  }

  // 도감 등록하기
  Future<void> _completePet() async {
    if (_currentPet == null || !_currentPet!.canComplete) return;
    
    try {
      final result = await AnimalCollectorService.completePet(
        userId: _currentUser!.id,
        currentUser: _currentUser!,
      );
      
      if (result['success']) {
        setState(() {
          _currentUser = result['user'];
          _currentPet = null;
          _currentSpecies = null;
        });
        
        // 도감 등록 완료 다이얼로그 표시
        _showCompletionDialog(result);
      } else {
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      _showErrorSnackBar('도감 등록 중 오류가 발생했습니다: $e');
    }
  }

  // 키우기 포기
  Future<void> _abandonPet() async {
    if (_currentPet == null) return;
    
    final confirmed = await _showConfirmDialog(
      '키우기 포기',
      '정말로 ${_currentPet!.nickname}을(를) 포기하시겠습니까?\n현재 상태로 도감에 등록됩니다.',
    );
    
    if (!confirmed) return;
    
    try {
      final result = await AnimalCollectorService.abandonPet(
        userId: _currentUser!.id,
        currentUser: _currentUser!,
      );
      
      if (result['success']) {
        setState(() {
          _currentUser = result['user'];
          _currentPet = null;
          _currentSpecies = null;
        });
        
        _showSuccessSnackBar(result['message']);
      } else {
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      _showErrorSnackBar('포기 처리 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petCoralLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app,
              color: AppColors.petCoral,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '동물 클리커',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.petCoral,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // 도감 버튼
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimalCollectionPage(currentUser: _currentUser!),
                ),
              );
            },
            icon: Icon(
              Icons.collections_bookmark,
              color: AppColors.petCoral,
              size: 20,
            ),
            tooltip: '도감',
          ),
          
          // 포인트 표시
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.petCoralLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.petCoral.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 16,
                  color: AppColors.petCoral,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentUser?.rewardPoints ?? 0}P',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.petCoral,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPet == null
              ? _buildGachaScreen()
              : _buildPetCareScreen(),
    );
  }

  // 뽑기 화면 (기존과 동일)
  Widget _buildGachaScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // 뽑기 제목
          Text(
            '🎲 동물 뽑기',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.petCoral,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 동물 친구를 만나보세요!',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.petCoral,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 신비로운 상자 이미지
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.petCoralLight,
                  AppColors.petCoral.withOpacity(0.7),
                  AppColors.petCoralDark.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.petCoral.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🎁',
                style: TextStyle(fontSize: 80),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 확률 정보
          _buildProbabilityInfo(),
          
          const SizedBox(height: 40),
          
          // 뽑기 버튼들
          _buildGachaButtons(),
          
          const SizedBox(height: 20),
          
          // 도감 보기 버튼
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimalCollectionPage(currentUser: _currentUser!),
                ),
              );
            },
            icon: Icon(
              Icons.collections_bookmark,
              color: AppColors.petCoral,
              size: 18,
            ),
            label: Text(
              '📖 도감 보기',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.petCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 확률 정보
  Widget _buildProbabilityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🎯 뽑기 확률',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProbabilityItem('⭐', '일반', '70%', AppColors.petCoral),
              _buildProbabilityItem('⭐⭐', '희귀', '25%', AppColors.petCoralDark),
              _buildProbabilityItem('⭐⭐⭐', '전설', '5%', AppColors.petCoral.withOpacity(0.8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityItem(String stars, String name, String percent, Color color) {
    return Column(
      children: [
        Text(
          stars,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          percent,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // 뽑기 버튼들
  Widget _buildGachaButtons() {
    return Column(
      children: [
        // 무료 뽑기
        if (_canUseFreeGacha)
          Container(
            width: double.infinity,
            height: 60,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: () => _performGacha(isFree: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.petCoral,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '🎁 무료 뽑기 (24시간마다)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // 포인트 뽑기
        Container(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: (_currentUser?.rewardPoints ?? 0) >= 500
                ? () => _performGacha(isFree: false)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.petCoralDark,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, size: 24),
                SizedBox(width: 8),
                Text(
                  '💰 포인트 뽑기 (500P)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 클릭커 게임 화면
  Widget _buildPetCareScreen() {
    if (_currentPet == null || _currentSpecies == null) {
      return const Center(child: Text('동물 정보를 불러올 수 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 동물 정보 카드
          _buildPetInfoCard(),
          
          const SizedBox(height: 20),
          
          // 클릭 영역 (메인)
          _buildClickArea(),
          
          const SizedBox(height: 20),
          
          // 성장 바
          _buildGrowthBar(),
          
          const SizedBox(height: 20),
          
          // 업그레이드 상점
          _buildUpgradeShop(),
          
          const SizedBox(height: 20),
          
          // 테스트용 레벨업 버튼 (개발 모드에서만 표시)
          if (kDebugMode) _buildTestButtons(),
          
          const SizedBox(height: 20),
          
          // 완료/포기 버튼들
          _buildControlButtons(),
        ],
      ),
    );
  }

  // 동물 정보 카드
  Widget _buildPetInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _currentSpecies!.rarityStars,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentPet!.nickname,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _currentPet!.moodEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_currentPet!.moodDescription} • 클릭 ${_currentPet!.totalClicks}회',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              if (_currentPet!.comboCount > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentPet!.comboCount >= 50 
                        ? Colors.red.shade100
                        : _currentPet!.comboCount >= 20
                            ? Colors.orange.shade100
                            : Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _currentPet!.comboCount >= 50 
                          ? Colors.red.shade300
                          : _currentPet!.comboCount >= 20
                              ? Colors.orange.shade300
                              : Colors.yellow.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPet!.comboCount >= 50 
                            ? '🔥🔥🔥'
                            : _currentPet!.comboCount >= 20
                                ? '🔥🔥'
                                : '🔥',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentPet!.comboCount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _currentPet!.comboCount >= 50 
                              ? Colors.red.shade700
                              : _currentPet!.comboCount >= 20
                                  ? Colors.orange.shade700
                                  : Colors.yellow.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 클릭 영역 (메인)
  Widget _buildClickArea() {
    return GestureDetector(
      onTap: _clickPet,
      child: AnimatedBuilder(
        animation: _petScaleAnimation,
        builder: (context, child) {
          return AnimatedBuilder(
            animation: _clickScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _petScaleAnimation.value * _clickScaleAnimation.value,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.petCoralLight,
                        AppColors.petCoral.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.petCoral.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentSpecies!.displayEmoji,
                          style: const TextStyle(fontSize: 100),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '탭하세요!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 성장 바
  Widget _buildGrowthBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⭐ 레벨 ${_currentPet!.level}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _currentPet!.currentTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.petCoral,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                _currentPet!.level >= 99 
                    ? 'MAX' 
                    : '${_currentPet!.experience.toInt()}/${_currentPet!.requiredExp.toInt()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.petCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _currentPet!.expProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _currentPet!.level >= 99 ? Colors.amber.shade400 : AppColors.petCoral
            ),
            minHeight: 12,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '클릭 파워: +${_currentPet!.clickPower.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '총 클릭: ${_currentPet!.totalClicks}회',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 업그레이드 상점
  Widget _buildUpgradeShop() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🛒 업그레이드 상점',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 클릭 파워 업그레이드만 유지
          _buildUpgradeItem(
            '💪 클릭 파워',
            '클릭당 성장량 +0.5%',
            '${(_currentPet!.clickPower * 100).round()}P',
            'clickPower',
            (_currentUser?.rewardPoints ?? 0) >= (_currentPet!.clickPower * 100).round(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeItem(String title, String description, String cost, String upgradeType, bool canAfford) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canAfford ? AppColors.petCoralLight : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canAfford ? AppColors.petCoral : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: canAfford ? AppColors.petCoral : Colors.grey.shade600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canAfford ? () => _purchaseUpgrade(upgradeType) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? AppColors.petCoral : Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              cost,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 테스트용 레벨업 버튼 (개발 모드에서만 표시)
  Widget _buildTestButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.developer_mode,
                color: Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '🚀 개발자 테스트 메뉴',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentPet!.level < 99 ? () => _levelUpPet() : null,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: Text(
                    _currentPet!.level >= 99 
                        ? '최대 레벨 (Lv.99)' 
                        : '레벨업! (${_currentPet!.level} → ${_currentPet!.level + 1})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPet!.level >= 99 
                        ? Colors.grey.shade400 
                        : Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addTestPoints(),
                  icon: const Icon(Icons.monetization_on, size: 18),
                  label: const Text(
                    '포인트 충전 (+10000P)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '현재: Lv.${_currentPet!.level} (경험치 ${_currentPet!.experience.toInt()}/${_currentPet!.level >= 99 ? "MAX" : _currentPet!.requiredExp.toInt()}) | 포인트: ${_currentUser!.rewardPoints}P',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // 완료/포기 버튼들
  Widget _buildControlButtons() {
    return Row(
      children: [
        // 도감 등록 버튼
        Expanded(
          child: ElevatedButton(
            onPressed: _currentPet!.canComplete ? _completePet : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPet!.canComplete 
                  ? Colors.amber.shade400 
                  : Colors.grey.shade300,
              foregroundColor: Colors.white,
              elevation: _currentPet!.canComplete ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _currentPet!.canComplete 
                  ? '📖 도감 등록 (Lv.${_currentPet!.level})' 
                  : 'Lv.2 달성 필요',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // 포기 버튼
        Expanded(
          child: ElevatedButton(
            onPressed: _abandonPet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              '😢 그만 키우기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 뽑기 결과 다이얼로그
  void _showGachaResultDialog(Map<String, dynamic> result) {
    final species = result['species'] as AnimalSpecies;
    final pet = result['pet'] as CurrentPet;
    final isLegendary = result['isLegendary'] as bool;
    final isRare = result['isRare'] as bool;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 등급별 효과
            if (isLegendary)
              const Text(
                '🎉 전설 등급! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              )
            else if (isRare)
              const Text(
                '✨ 희귀 등급! ✨',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              )
            else
              const Text(
                '🌟 새로운 친구!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // 동물 이미지
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isLegendary
                      ? [Colors.purple.shade200, Colors.pink.shade200]
                      : isRare
                          ? [Colors.blue.shade200, Colors.cyan.shade200]
                          : [Colors.green.shade200, Colors.lime.shade200],
                ),
              ),
              child: Center(
                child: Text(
                  species.displayEmoji,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 동물 정보
            Text(
              species.rarityStars,
              style: const TextStyle(fontSize: 20),
            ),
            Text(
              species.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              species.flavorText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '키우기 시작!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 도감 등록 완료 다이얼로그
  void _showCompletionDialog(Map<String, dynamic> result) {
    final collectedAnimal = result['collectedAnimal'] as CollectedAnimal?;
    final rewardPoints = result['rewardPoints'] as int? ?? 0;
    final message = result['message'] as String? ?? '도감에 등록되었습니다!';
    
    // 등록된 동물의 종족 정보 가져오기
    AnimalSpecies? completedSpecies;
    if (collectedAnimal != null) {
      completedSpecies = AnimalData.getSpeciesById(collectedAnimal.speciesId);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 축하 제목
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade300,
                    Colors.blue.shade300,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '📖 도감 등록 완료! 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 동물 이미지 - 등록된 동물의 정보 사용
            if (completedSpecies != null)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: completedSpecies.rarity == AnimalRarity.legendary
                        ? [Colors.purple.shade200, Colors.pink.shade200]
                        : completedSpecies.rarity == AnimalRarity.rare
                            ? [Colors.blue.shade200, Colors.cyan.shade200]
                            : [Colors.green.shade200, Colors.lime.shade200],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: completedSpecies.rarity == AnimalRarity.legendary
                          ? Colors.purple.shade300
                          : completedSpecies.rarity == AnimalRarity.rare
                              ? Colors.blue.shade300
                              : Colors.green.shade300,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    completedSpecies.displayEmoji,
                    style: const TextStyle(fontSize: 70),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 동물 정보
            if (completedSpecies != null) ...[
              Text(
                completedSpecies.rarityStars,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                completedSpecies.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '닉네임: ${collectedAnimal?.nickname ?? ""}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 보상 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                '보상: +${rewardPoints}P',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 메시지
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 확인 다이얼로그
  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // 성공 스낵바
  void _showSuccessSnackBar(String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  // 에러 스낵바
  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }

  // 레벨업 기능 구현
  Future<void> _levelUpPet() async {
    if (_currentPet == null) return;
    
    try {
      final result = await AnimalCollectorService.levelUpPet(
        _currentUser!.id,
        currentUser: _currentUser!,
      );
      
      if (result['success']) {
        setState(() {
          _currentUser = result['user'];
          _currentPet = result['pet'];
        });
        
        _showSuccessSnackBar('레벨업 완료! 새로운 레벨: ${_currentPet!.level}');
      } else {
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      _showErrorSnackBar('레벨업 중 오류가 발생했습니다: $e');
    }
  }

  // 테스트용 포인트 충전 기능 구현
  Future<void> _addTestPoints() async {
    if (_currentUser == null) return;
    
    try {
      final result = await AnimalCollectorService.addTestPoints(
        _currentUser!.id,
        currentUser: _currentUser!,
      );
      
      if (result['success']) {
        setState(() {
          _currentUser = result['user'];
        });
        
        _showSuccessSnackBar('포인트 충전 완료! 현재 포인트: ${_currentUser!.rewardPoints}P');
      } else {
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      _showErrorSnackBar('포인트 충전 중 오류가 발생했습니다: $e');
    }
  }
} 