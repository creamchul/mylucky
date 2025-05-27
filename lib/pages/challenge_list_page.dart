import 'package:flutter/material.dart';

// Models imports
import '../models/models.dart';
import '../data/mission_data.dart';

// Services imports
import '../services/challenge_service.dart';

// Pages imports
import 'challenge_detail_page.dart';

class ChallengeListPage extends StatefulWidget {
  final UserModel currentUser;
  
  const ChallengeListPage({super.key, required this.currentUser});

  @override
  State<ChallengeListPage> createState() => _ChallengeListPageState();
}

class _ChallengeListPageState extends State<ChallengeListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserModel _currentUser;
  
  final List<ChallengeCategory> _categories = ChallengeData.allCategories;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            color: Colors.orange.shade400,
          ),
          onPressed: () => Navigator.pop(context, _currentUser),
        ),
        title: Text(
          '모든 챌린지',
          style: TextStyle(
            color: Colors.orange.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.orange.shade400,
          labelColor: Colors.orange.shade600,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: _categories.map((category) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji),
                const SizedBox(width: 6),
                Text(category.displayName),
              ],
            ),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) => _buildCategoryTab(category)).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(ChallengeCategory category) {
    final challenges = ChallengeService.getChallengesByCategory(category);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 설명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCategoryColor(category).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: _getCategoryColor(category),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 챌린지 목록
          ...challenges.map((challenge) => _buildChallengeCard(challenge)).toList(),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _navigateToChallengeDetail(challenge),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 (이모지, 제목, 난이도)
                Row(
                  children: [
                    Text(
                      challenge.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    // 난이도 표시
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(challenge.difficulty).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(
                            challenge.difficulty.level,
                            (index) => Icon(
                              Icons.star,
                              size: 10,
                              color: _getDifficultyColor(challenge.difficulty),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // 설명
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // 정보 (기간, 보상)
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: '${challenge.durationDays}일',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.stars,
                      label: '${challenge.pointsReward}P',
                      color: Colors.amber,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToChallengeDetail(Challenge challenge) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailPage(
          challenge: challenge,
          currentUser: _currentUser,
        ),
      ),
    );

    if (result != null && result is UserModel) {
      setState(() {
        _currentUser = result;
      });
    }
  }

  Color _getCategoryColor(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.health:
        return Colors.green;
      case ChallengeCategory.growth:
        return Colors.blue;
      case ChallengeCategory.mindfulness:
        return Colors.purple;
      case ChallengeCategory.productivity:
        return Colors.orange;
      case ChallengeCategory.social:
        return Colors.pink;
      case ChallengeCategory.creativity:
        return Colors.teal;
    }
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.orange;
      case ChallengeDifficulty.hard:
        return Colors.red;
    }
  }
} 