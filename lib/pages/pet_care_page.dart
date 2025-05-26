import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Models imports
import '../models/models.dart';

// Services imports
import '../services/pet_service.dart';
import '../services/reward_service.dart';

class PetCarePage extends StatefulWidget {
  final UserModel currentUser;

  const PetCarePage({
    super.key,
    required this.currentUser,
  });

  @override
  State<PetCarePage> createState() => _PetCarePageState();
}

class _PetCarePageState extends State<PetCarePage> with TickerProviderStateMixin {
  List<PetModel> _pets = [];
  bool _isLoading = true;
  late UserModel _currentUser;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _tabController = TabController(length: 2, vsync: this);
    _loadUserPets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final availablePets = PetService.getAvailablePetsForAdoption();
    
    await showDialog(
      context: context,
      builder: (context) => _AdoptionDialog(
        availablePets: availablePets,
        onAdopt: _adoptPet,
      ),
    );
  }

  Future<void> _adoptPet(PetType type, String species, String name) async {
    try {
      final result = await PetService.adoptPet(
        currentUser: _currentUser,
        name: name,
        type: type,
        species: species,
      );

      setState(() {
        _pets.insert(0, result['pet']);
        _currentUser = result['user'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 $name을(를) 입양했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('입양 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _growPet(PetModel pet) async {
    try {
      final result = await PetService.growPet(
        currentUser: _currentUser,
        pet: pet,
      );

      setState(() {
        final index = _pets.indexWhere((p) => p.id == pet.id);
        if (index != -1) {
          _pets[index] = result['pet'];
        }
        _currentUser = result['user'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌟 ${pet.name}이(가) ${result['pet'].stageDisplayName} 단계로 성장했습니다!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('성장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              Icons.pets,
              color: Colors.green.shade400,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              '키우기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
        actions: [
          // 포인트 표시
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green.shade600,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.green.shade400,
          tabs: const [
            Tab(text: '내 펫'),
            Tab(text: '입양하기'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8F0), // 연한 녹색
              Color(0xFFF8FFF8), // 더 연한 녹색
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMyPetsTab(),
            _buildAdoptionTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPetsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 키우고 있는 펫이 없어요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '입양하기 탭에서 새로운 친구를 만나보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserPets,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _pets.length,
          itemBuilder: (context, index) {
            final pet = _pets[index];
            return _PetCard(
              pet: pet,
              currentUser: _currentUser,
              onGrow: () => _growPet(pet),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdoptionTab() {
    final availablePets = PetService.getAvailablePetsForAdoption();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  '새로운 친구들을 무료로 입양할 수 있어요!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '입양 후 포인트를 사용해서 성장시켜 주세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            '입양 가능한 친구들',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: availablePets.length,
              itemBuilder: (context, index) {
                final petData = availablePets[index];
                return _AdoptionCard(
                  petData: petData,
                  onTap: () => _showPetNamingDialog(
                    petData['type'],
                    petData['species'],
                    petData['displayName'],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPetNamingDialog(PetType type, String species, String displayName) async {
    String petName = '';
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '$displayName 입양하기',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '새로운 친구의 이름을 지어주세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => petName = value,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: '예: 복실이, 모모 등',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.green.shade400),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (PetService.isValidPetName(petName)) {
                Navigator.of(context).pop();
                _adoptPet(type, species, petName.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('입양하기'),
          ),
        ],
      ),
    );
  }
}

// 펫 카드 위젯
class _PetCard extends StatelessWidget {
  final PetModel pet;
  final UserModel currentUser;
  final VoidCallback onGrow;

  const _PetCard({
    required this.pet,
    required this.currentUser,
    required this.onGrow,
  });

  @override
  Widget build(BuildContext context) {
    final canGrow = pet.canGrow;
    final hasEnoughPoints = RewardService.hasEnoughPoints(currentUser, pet.pointsToNextStage);
    final stageEmoji = PetService.getStageEmoji(pet.stage);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 펫 정보
            Expanded(
              child: Column(
                children: [
                  // 펫 아이콘과 이름
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      stageEmoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    '${pet.speciesDisplayName} • ${pet.stageDisplayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 성장 정보
                  if (canGrow) ...[
                    Text(
                      '다음 성장까지',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '${pet.pointsToNextStage} 포인트',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '최고 단계!',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 성장 버튼
            if (canGrow)
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: hasEnoughPoints ? onGrow : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasEnoughPoints ? Colors.green.shade400 : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    hasEnoughPoints ? '성장시키기' : '포인트 부족',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 입양 카드 위젯
class _AdoptionCard extends StatelessWidget {
  final Map<String, dynamic> petData;
  final VoidCallback onTap;

  const _AdoptionCard({
    required this.petData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                petData['icon'],
                style: const TextStyle(fontSize: 40),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                petData['displayName'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '무료 입양',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 입양 다이얼로그 위젯
class _AdoptionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> availablePets;
  final Function(PetType, String, String) onAdopt;

  const _AdoptionDialog({
    required this.availablePets,
    required this.onAdopt,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text('새로운 친구 입양하기'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: availablePets.length,
          itemBuilder: (context, index) {
            final petData = availablePets[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                // 펫 이름 입력 다이얼로그 표시 로직은 호출하는 쪽에서 처리
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      petData['icon'],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      petData['displayName'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
} 