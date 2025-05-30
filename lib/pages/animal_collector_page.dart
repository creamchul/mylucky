import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/animal_collector_service.dart';
import '../data/animal_data.dart';
import 'animal_collection_page.dart';
import '../utils/snackbar_utils.dart';
import '../constants/app_colors.dart';

class AnimalCollectorPage extends StatefulWidget {
  final UserModel currentUser;

  const AnimalCollectorPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<AnimalCollectorPage> createState() => _AnimalCollectorPageState();
}

class _AnimalCollectorPageState extends State<AnimalCollectorPage>
    with TickerProviderStateMixin {
  UserModel? _currentUser;
  CurrentPet? _currentPet;
  AnimalSpecies? _currentSpecies;
  bool _isLoading = true;
  bool _canUseFreeGacha = false;
  String _lastActionMessage = ''; // 마지막 상호작용 메시지
  DateTime? _lastActionTime; // 마지막 상호작용 시간
  
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
        print('AnimalCollectorPage: 데이터 로드 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorPage: 데이터 로드 실패 - $e');
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

  // 동물 클릭
  Future<void> _clickPet() async {
    if (_currentPet == null) return;
    
    try {
      // 클릭 애니메이션 실행
      _clickAnimationController.forward().then((_) {
        _clickAnimationController.reverse();
      });
      
      final updatedPet = await AnimalCollectorService.clickPet(_currentUser!.id);
      if (updatedPet != null) {
        setState(() {
          _currentPet = updatedPet;
        });
        
        // 콤보 효과는 UI에서 자동으로 표시됨 (별도 메시지 불필요)
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorPage: 클릭 처리 실패 - $e');
      }
    }
  }

  // 상호작용 (먹이주기, 놀기 등)
  Future<void> _performAction(String action) async {
    if (_currentPet == null || _currentUser == null) return;
    
    try {
      Map<String, dynamic> result;
      
      switch (action) {
        case 'feed':
          result = await AnimalCollectorService.feedPet(
            userId: _currentUser!.id,
            currentUser: _currentUser!,
          );
          break;
        case 'play':
          result = await AnimalCollectorService.playWithPet(
            userId: _currentUser!.id,
            currentUser: _currentUser!,
          );
          break;
        case 'rest':
          result = await AnimalCollectorService.restPet(
            userId: _currentUser!.id,
            currentUser: _currentUser!,
          );
          break;
        case 'train':
          result = await AnimalCollectorService.trainPet(
            userId: _currentUser!.id,
            currentUser: _currentUser!,
          );
          break;
        default:
          return;
      }
      
      if (result['success']) {
        setState(() {
          _currentUser = result['user'];
          _currentPet = result['pet'];
          _lastActionMessage = _getActionMessage(action);
          _lastActionTime = DateTime.now();
        });
        
        // 3초 후 메시지 자동 제거
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _lastActionMessage = '';
              _lastActionTime = null;
            });
          }
        });
      } else {
        _showErrorSnackBar(result['error']);
      }
    } catch (e) {
      _showErrorSnackBar('작업 중 오류가 발생했습니다: $e');
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
      _showErrorSnackBar('진화 중 오류가 발생했습니다: $e');
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
        
        // 성공 메시지는 UI에 인라인으로 표시됨
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
              Icons.pets,
              color: AppColors.petCoral,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '동물 콜렉터',
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
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.petCoral),
              ),
            )
          : _currentPet == null
              ? _buildGachaScreen()
              : _buildPetCareScreen(),
    );
  }

  // 뽑기 화면
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

  // 동물 키우기 화면
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
          
          // 동물 이미지 (클릭 가능)
          _buildPetImage(),
          
          const SizedBox(height: 20),
          
          // 상태 바들
          _buildStatusBars(),
          
          const SizedBox(height: 20),
          
          // 상호작용 버튼들
          _buildActionButtons(),
          
          const SizedBox(height: 20),
          
          // 진화/포기 버튼들
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentPet!.personalityDescription} • ${_currentPet!.moodDescription}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    // 최근 상호작용 메시지 표시
                    if (_lastActionMessage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AnimatedOpacity(
                        opacity: _lastActionMessage.isNotEmpty ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _lastActionMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_currentPet!.comboCount > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentPet!.comboCount >= 20 
                        ? Colors.red.shade100
                        : _currentPet!.comboCount >= 10
                            ? Colors.orange.shade100
                            : Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _currentPet!.comboCount >= 20 
                          ? Colors.red.shade300
                          : _currentPet!.comboCount >= 10
                              ? Colors.orange.shade300
                              : Colors.yellow.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentPet!.comboCount >= 20 
                            ? '🔥🔥🔥'
                            : _currentPet!.comboCount >= 10
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
                          color: _currentPet!.comboCount >= 20 
                              ? Colors.red.shade700
                              : _currentPet!.comboCount >= 10
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

  // 동물 이미지 (클릭 가능) - 고정 크기로 안정화
  Widget _buildPetImage() {
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
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade100,
                        Colors.purple.shade100,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        _currentSpecies!.getPersonalityEmoji(_currentPet!.personality.toString().split('.').last),
                        style: const TextStyle(fontSize: 72),
                      ),
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

  // 상태 바들
  Widget _buildStatusBars() {
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
          _buildStatusBar('⚡ 에너지', _currentPet!.energy, Colors.orange),
          const SizedBox(height: 12),
          _buildStatusBar('💖 행복도', _currentPet!.happiness, Colors.pink),
          const SizedBox(height: 12),
          _buildStatusBar('📈 성장도', _currentPet!.growth, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, double value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  // 상호작용 버튼들 - 고정 레이아웃으로 안정화
  Widget _buildActionButtons() {
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
          const Text(
            '🎮 상호작용',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 고정 크기 그리드로 변경
          SizedBox(
            height: 120, // 고정 높이
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: _buildActionButton(
                          '🍎 먹이주기',
                          '10P',
                          Colors.green,
                          () => _performAction('feed'),
                          enabled: (_currentUser?.rewardPoints ?? 0) >= 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: _buildActionButton(
                          '🎾 놀아주기',
                          '15P',
                          Colors.blue,
                          () => _performAction('play'),
                          enabled: (_currentUser?.rewardPoints ?? 0) >= 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: _buildActionButton(
                          '💤 휴식하기',
                          '5P',
                          Colors.purple,
                          () => _performAction('rest'),
                          enabled: (_currentUser?.rewardPoints ?? 0) >= 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: _buildActionButton(
                          '🎓 훈련하기',
                          '20P',
                          Colors.orange,
                          () => _performAction('train'),
                          enabled: (_currentUser?.rewardPoints ?? 0) >= 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String cost,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade300,
        foregroundColor: Colors.white,
        elevation: enabled ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero, // 최소 크기 제거
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 최소화
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            cost,
            style: const TextStyle(
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // 도감등록/포기 버튼들
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
              _currentPet!.canComplete ? '📖 도감 등록' : '친밀도 ${_currentPet!.growth.toInt()}%',
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
                  species.baseEmoji,
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

  // 진화 결과 다이얼로그 (일반 진화)
  void _showEvolutionDialog(Map<String, dynamic> result) {
    final pet = result['pet'] as CurrentPet?;
    final message = result['message'] as String;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '✨ 진화 성공!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pet != null && _currentSpecies != null)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade200,
                      Colors.orange.shade200,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.shade200,
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      _currentSpecies!.getPersonalityEmoji(pet.personality.toString().split('.').last),
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 도감 등록 완료 다이얼로그
  void _showCompletionDialog(Map<String, dynamic> result) {
    final collectedAnimal = result['collectedAnimal'] as CollectedAnimal?;
    final message = result['message'] as String? ?? '도감에 등록되었습니다!';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 동물 이미지
                if (_currentSpecies != null)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade200,
                          Colors.blue.shade200,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade300,
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          _currentSpecies!.getPersonalityEmoji(collectedAnimal?.personality ?? 'balanced'),
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // 동물 정보
                if (_currentSpecies != null && collectedAnimal != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentSpecies!.rarityStars,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          collectedAnimal.nickname,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        collectedAnimal.personalityDisplayName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentSpecies!.flavorText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 메시지
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 확인 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

  // 최종 진화 다이얼로그 (특별 처리) - 더 이상 사용하지 않음
  void _showFinalEvolutionDialog(Map<String, dynamic> result) {
    final pet = result['pet'] as CurrentPet?;
    final message = result['message'] as String;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 축하 제목
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade300,
                      Colors.orange.shade300,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🎉 완전 진화 달성! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 최종 진화 동물 이미지
              if (pet != null && _currentSpecies != null)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade200,
                        Colors.orange.shade200,
                        Colors.red.shade200,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade300,
                        blurRadius: 25,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        _currentSpecies!.getPersonalityEmoji(_currentPet?.personality.toString().split('.').last ?? 'balanced'),
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // 동물 이름과 설명
              if (_currentSpecies != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentSpecies!.rarityStars,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currentPet?.nickname ?? _currentSpecies!.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '👑',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentSpecies!.flavorText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              
              // 메시지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 도감 등록 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 현재 펫 제거 (도감에 이미 등록됨)
                    setState(() {
                      _currentPet = null;
                      _currentSpecies = null;
                    });
                    // 도감 등록 완료는 화면 전환으로 충분히 표현됨
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade400,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '📖 도감에 등록하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

  // 콤보 효과 표시 (가벼운 오버레이로 변경)
  void _showComboEffect(int combo) {
    // 스낵바 대신 가벼운 오버레이 사용하지 않고 상태로만 표시
    // 콤보는 이미 UI에 표시되므로 별도 메시지 불필요
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

  // 액션별 메시지 생성
  String _getActionMessage(String action) {
    switch (action) {
      case 'feed':
        return '🍎 맛있게 먹었어요!';
      case 'play':
        return '🎾 즐겁게 놀았어요!';
      case 'rest':
        return '💤 편안히 쉬고 있어요!';
      case 'train':
        return '🎓 열심히 훈련했어요!';
      default:
        return '✨ 상호작용 완료!';
    }
  }

  // 에러 스낵바 (에러는 여전히 스낵바로 표시)
  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }
} 