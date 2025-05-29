import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/animal_collector_service.dart';
import '../data/animal_data.dart';

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
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_bookmark,
              color: Colors.indigo.shade600,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '동물 도감',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade600,
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
              color: Colors.indigo.shade600,
            ),
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
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 수집 통계
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.shade100,
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
                      color: Colors.indigo.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '수집 현황',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
          
          const SizedBox(height: 16),
          
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
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (total.isNotEmpty)
                TextSpan(
                  text: '/$total',
                  style: TextStyle(
                    fontSize: 14,
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
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.indigo.shade400 : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.indigo.shade600,
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.indigo.shade200,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
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
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '해당하는 동물이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9, // 비율을 조금 늘려서 이미지가 더 잘 보이도록 함
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
              padding: const EdgeInsets.all(12),
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
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16,
                    ),
                ],
              ),
            ),
            
            // 동물 이미지
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                  child: Text(
                    isDiscovered
                        ? species.displayEmoji
                        : '❓',
                      style: const TextStyle(fontSize: 52),
                    ),
                  ),
                ),
              ),
            ),
            
            // 하단 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    isDiscovered ? species.name : '???',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDiscovered ? Colors.grey.shade800 : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDiscovered
                        ? collected!.statusDescription
                        : '미발견',
                    style: TextStyle(
                      fontSize: 10,
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
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                          style: const TextStyle(fontSize: 24),
                        ),
                        if (isDiscovered && collected!.isCompleted) ...[
                          const SizedBox(width: 8),
                          Text(
                            '👑',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isDiscovered ? species.name : '???',
                      style: TextStyle(
                        fontSize: 20,
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  children: [
                    // 동물 이미지
                    Container(
                      width: 150,
                      height: 150,
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
                            style: const TextStyle(fontSize: 75),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
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
                        padding: const EdgeInsets.all(12),
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              species.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 특수 능력
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getRarityColor(species.rarity),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              species.specialAbility,
                              style: TextStyle(
                                fontSize: 14,
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 32,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '아직 발견하지 못한 동물입니다',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '뽑기를 통해 새로운 친구를 만나보세요!',
                              style: TextStyle(
                                fontSize: 12,
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
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: 16,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
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