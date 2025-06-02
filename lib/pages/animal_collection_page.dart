import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/animal_collector_service.dart';
import '../data/animal_data.dart';
import '../constants/app_colors.dart';

class AnimalCollectionPage extends StatefulWidget {
  final UserModel currentUser;

  const AnimalCollectionPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<AnimalCollectionPage> createState() => _AnimalCollectionPageState();
}

class _AnimalCollectionPageState extends State<AnimalCollectionPage>
    with TickerProviderStateMixin {
  List<CollectedAnimal> _collection = [];
  List<AnimalSpecies> _allSpecies = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, common, rare, legendary, completed
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadCollection();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCollection() async {
    try {
      setState(() => _isLoading = true);
      
      final collection = await AnimalCollectorService.getCollection(widget.currentUser.id);
      final allSpecies = AnimalData.allSpecies;
      
      setState(() {
        _collection = collection;
        _allSpecies = allSpecies;
        _isLoading = false;
      });
      
      if (kDebugMode) {
        print('AnimalCollectionPage: 도감 로드 완료 - ${collection.length}개 수집');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectionPage: 도감 로드 실패 - $e');
      }
      setState(() => _isLoading = false);
    }
  }

  // 필터링된 동물 목록 가져오기
  List<AnimalSpecies> get _filteredSpecies {
    switch (_selectedFilter) {
      case 'common':
        return _allSpecies.where((s) => s.rarity == AnimalRarity.common).toList();
      case 'rare':
        return _allSpecies.where((s) => s.rarity == AnimalRarity.rare).toList();
      case 'legendary':
        return _allSpecies.where((s) => s.rarity == AnimalRarity.legendary).toList();
      case 'completed':
        final completedIds = _collection.where((c) => c.isCompleted).map((c) => c.speciesId).toSet();
        return _allSpecies.where((s) => completedIds.contains(s.id)).toList();
      default:
        return _allSpecies;
    }
  }

  // 동물이 수집되었는지 확인
  CollectedAnimal? _getCollectedAnimal(String speciesId) {
    try {
      return _collection.firstWhere((c) => c.speciesId == speciesId);
    } catch (e) {
      return null;
    }
  }

  // 수집 통계
  Map<String, int> get _collectionStats {
    final total = _allSpecies.length;
    final collected = _collection.length;
    final completed = _collection.where((c) => c.isCompleted).length;
    
    return {
      'total': total,
      'collected': collected,
      'completed': completed,
      'percentage': total > 0 ? ((collected / total) * 100).round() : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.petCoral,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
          iconSize: 22,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_bookmark,
              color: AppColors.petCoral,
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '동물 도감',
                style: TextStyle(
                  fontSize: 20,
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
          IconButton(
            onPressed: _loadCollection,
            icon: Icon(
              Icons.refresh,
              color: AppColors.petCoral,
              size: 22,
            ),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // 통계 및 필터
                  _buildHeader(),
                  
                  // 동물 그리드
                  Expanded(
                    child: _buildAnimalGrid(),
                  ),
                ],
              ),
            ),
    );
  }

  // 헤더 (통계 + 필터)
  Widget _buildHeader() {
    final stats = _collectionStats;
    
    return Container(
      margin: const EdgeInsets.all(18),
      child: Column(
        children: [
          // 수집 통계
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.petCoral.withOpacity(0.1),
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
                      Icons.auto_awesome,
                      color: AppColors.petCoral,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '수집 현황',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.petCoralDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('발견', '${stats['collected']}', '${stats['total']}', Colors.blue),
                    _buildStatItem('완성', '${stats['completed']}', '${stats['collected']}', Colors.green),
                    _buildStatItem('진행률', '${stats['percentage']}%', '', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 필터 버튼들
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton('전체', 'all'),
                _buildFilterButton('일반 ⭐', 'common'),
                _buildFilterButton('희귀 ⭐⭐', 'rare'),
                _buildFilterButton('전설 ⭐⭐⭐', 'legendary'),
                _buildFilterButton('완성 ✨', 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String total, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (total.isNotEmpty)
                TextSpan(
                  text: '/$total',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.petCoral : Colors.white,
          foregroundColor: isSelected ? Colors.white : AppColors.petCoral,
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.petCoral.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          minimumSize: const Size(80, 44),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // 동물 그리드
  Widget _buildAnimalGrid() {
    final filteredSpecies = _filteredSpecies;
    
    if (filteredSpecies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 68,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              '해당하는 동물이 없습니다',
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: filteredSpecies.length,
      itemBuilder: (context, index) {
        final species = filteredSpecies[index];
        final collected = _getCollectedAnimal(species.id);
        
        return _buildAnimalCard(species, collected);
      },
    );
  }

  // 동물 카드
  Widget _buildAnimalCard(AnimalSpecies species, CollectedAnimal? collected) {
    final isDiscovered = collected != null;
    final isCompleted = collected?.isCompleted ?? false;
    
    return GestureDetector(
      onTap: () => _showAnimalDetail(species, collected),
      child: Container(
        // 모바일 최적화: 최소 터치 높이 보장
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? Colors.amber.shade300
                : isDiscovered
                    ? _getRarityColor(species.rarity).withOpacity(0.5)
                    : Colors.grey.shade300,
            width: isCompleted ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? Colors.amber.shade100
                  : isDiscovered
                      ? _getRarityColor(species.rarity).withOpacity(0.2)
                      : Colors.grey.shade100,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 상단 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14), // 기존: 12에서 14로 증가
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.amber.shade50
                    : isDiscovered
                        ? _getRarityColor(species.rarity).withOpacity(0.1)
                        : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    species.rarityStars,
                    style: const TextStyle(fontSize: 18), // 기존: 16에서 18로 증가
                  ),
                  const Spacer(),
                  if (isCompleted)
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 18, // 기존: 16에서 18로 증가
                    ),
                ],
              ),
            ),
            
            // 동물 이미지
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16), // 기존: 8,12에서 증가
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                  child: Text(
                    isDiscovered
                        ? species.displayEmoji
                        : '❓',
                      style: const TextStyle(fontSize: 56), // 기존: 52에서 56으로 증가
                    ),
                  ),
                ),
              ),
            ),
            
            // 하단 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14), // 기존: 12에서 14로 증가
              child: Column(
                children: [
                  Text(
                    isDiscovered ? species.name : '???',
                    style: TextStyle(
                      fontSize: 15, // 기존: 14에서 15로 증가
                      fontWeight: FontWeight.bold,
                      color: isDiscovered ? Colors.grey.shade800 : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5), // 기존: 4에서 5로 증가
                  Text(
                    isDiscovered
                        ? collected!.statusDescription
                        : '미발견',
                    style: TextStyle(
                      fontSize: 11, // 기존: 10에서 11로 증가
                      color: isCompleted
                          ? Colors.amber.shade700
                          : isDiscovered
                              ? _getRarityColor(species.rarity)
                              : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 동물 상세 정보 다이얼로그
  void _showAnimalDetail(AnimalSpecies species, CollectedAnimal? collected) {
    final isDiscovered = collected != null;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 모바일 최적화: 화면 크기에 따른 동적 크기
    final dialogWidth = screenWidth < 400 ? screenWidth * 0.95 : screenWidth * 0.9;
    final dialogHeight = screenHeight < 600 
        ? screenHeight * 0.9 
        : screenHeight < 700 
            ? screenHeight * 0.85 
            : screenHeight * 0.8;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: dialogHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24), // 기존: 20에서 24로 증가
                decoration: BoxDecoration(
                  color: isDiscovered
                      ? _getRarityColor(species.rarity).withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          species.rarityStars,
                          style: const TextStyle(fontSize: 28), // 기존: 24에서 28로 증가
                        ),
                        if (isDiscovered && collected!.isCompleted) ...[
                          const SizedBox(width: 10), // 기존: 8에서 10으로 증가
                          Text(
                            '👑',
                            style: const TextStyle(fontSize: 24), // 기존: 20에서 24로 증가
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10), // 기존: 8에서 10으로 증가
                    Text(
                      isDiscovered ? species.name : '???',
                      style: TextStyle(
                        fontSize: 22, // 기존: 20에서 22로 증가
                        fontWeight: FontWeight.bold,
                        color: isDiscovered ? Colors.grey.shade800 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 내용
              Expanded(
                child: SingleChildScrollView(
                  // 모바일 최적화: 패딩 증가
                  padding: const EdgeInsets.all(24), // 기존: 20에서 24로 증가
                  child: Column(
                  children: [
                    // 동물 이미지
                    Container(
                      width: 160, // 기존: 150에서 160으로 증가
                      height: 160, // 기존: 150에서 160으로 증가
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDiscovered
                              ? [
                                  _getRarityColor(species.rarity).withOpacity(0.3),
                                  _getRarityColor(species.rarity).withOpacity(0.1),
                                ]
                              : [
                                  Colors.grey.shade300,
                                  Colors.grey.shade100,
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDiscovered 
                                ? _getRarityColor(species.rarity).withOpacity(0.2)
                                : Colors.grey.shade200,
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            isDiscovered
                                ? species.displayEmoji
                                : '❓',
                            style: const TextStyle(fontSize: 80), // 기존: 75에서 80으로 증가
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24), // 기존: 20에서 24로 증가
                    
                    if (isDiscovered) ...[
                      // 수집 정보
                      _buildDetailRow('상태', collected!.statusDescription),
                      _buildDetailRow('레벨', 'Lv.${collected.completedLevel}'),
                      _buildDetailRow('총 클릭수', '${collected.totalClicks}회'),
                      _buildDetailRow('발견일', _formatDate(collected.discoveredDate)),
                      if (collected.isCompleted && collected.completedDate != null)
                        _buildDetailRow('완성일', _formatDate(collected.completedDate!)),
                      _buildDetailRow('키운 기간', '${collected.daysSpent}일'),
                      
                      const SizedBox(height: 16),
                      
                      // 동물 설명
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16), // 기존: 12에서 16으로 증가
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '설명',
                              style: TextStyle(
                                fontSize: 14, // 기존: 12에서 14로 증가
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6), // 기존: 4에서 6으로 증가
                            Text(
                              species.description,
                              style: TextStyle(
                                fontSize: 15, // 기존: 14에서 15로 증가
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12), // 기존: 8에서 12로 증가
                      
                      // 특수 능력
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16), // 기존: 12에서 16으로 증가
                        decoration: BoxDecoration(
                          color: _getRarityColor(species.rarity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '특수 능력',
                              style: TextStyle(
                                fontSize: 14, // 기존: 12에서 14로 증가
                                fontWeight: FontWeight.bold,
                                color: _getRarityColor(species.rarity),
                              ),
                            ),
                            const SizedBox(height: 6), // 기존: 4에서 6으로 증가
                            Text(
                              species.specialAbility,
                              style: TextStyle(
                                fontSize: 15, // 기존: 14에서 15로 증가
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // 미발견 상태
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20), // 기존: 16에서 20으로 증가
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 36, // 기존: 32에서 36으로 증가
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 10), // 기존: 8에서 10으로 증가
                            Text(
                              '아직 발견하지 못한 동물입니다',
                              style: TextStyle(
                                fontSize: 15, // 기존: 14에서 15로 증가
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6), // 기존: 4에서 6으로 증가
                            Text(
                              '뽑기를 통해 새로운 친구를 만나보세요!',
                              style: TextStyle(
                                fontSize: 13, // 기존: 12에서 13으로 증가
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  ),
                ),
              ),
              
              // 닫기 버튼
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24), // 기존: 20에서 24로 증가
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDiscovered
                          ? _getRarityColor(species.rarity)
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // 모바일 최적화: 버튼 높이와 패딩 증가
                      padding: const EdgeInsets.symmetric(vertical: 16), // 기존: 12에서 16으로 증가
                      minimumSize: const Size(double.infinity, 52), // 최소 높이 보장
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: 18, // 기존: 16에서 18로 증가
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // 기존: 4에서 6으로 증가
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15, // 기존: 14에서 15로 증가
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15, // 기존: 14에서 15로 증가
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 등급별 색상
  Color _getRarityColor(AnimalRarity rarity) {
    switch (rarity) {
      case AnimalRarity.common:
        return Colors.green;
      case AnimalRarity.rare:
        return Colors.blue;
      case AnimalRarity.legendary:
        return Colors.purple;
    }
  }

  // 날짜 포맷
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
} 