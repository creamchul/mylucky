import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/models.dart';
import '../models/mood_entry_model.dart';
import '../services/mood_service.dart';
import '../services/theme_service.dart';
import '../widgets/mood_entry_dialog.dart';
import '../widgets/theme_toggle_widget.dart';
import 'mood_statistics_page.dart';
import 'activity_management_page.dart';

class MoodDiaryPage extends StatefulWidget {
  final UserModel currentUser;

  const MoodDiaryPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<MoodDiaryPage> createState() => _MoodDiaryPageState();
}

class _MoodDiaryPageState extends State<MoodDiaryPage> 
    with SingleTickerProviderStateMixin {
  Map<String, List<MoodEntryModel>> _groupedEntries = {};
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  late TabController _tabController;
  bool _showOnlyFavorites = false;
  int _favoriteCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadMoodEntries();
    _loadFavoriteCount();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _showOnlyFavorites = _tabController.index == 1;
    });
    _loadMoodEntries();
  }

  Future<void> _loadMoodEntries() async {
    setState(() => _isLoading = true);
    
    try {
      Map<String, List<MoodEntryModel>> groupedEntries;
      
      if (_showOnlyFavorites) {
        groupedEntries = await MoodService.getGroupedFavoriteEntriesByMonth(
          widget.currentUser.id,
          _selectedYear,
          _selectedMonth,
        );
      } else {
        groupedEntries = await MoodService.getGroupedMoodEntriesByMonth(
          widget.currentUser.id,
          _selectedYear,
          _selectedMonth,
        );
      }

      setState(() {
        _groupedEntries = groupedEntries;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('감정일기 로딩 실패: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavoriteCount() async {
    try {
      final count = await MoodService.getFavoriteCount(widget.currentUser.id);
      setState(() {
        _favoriteCount = count;
      });
    } catch (e) {
      if (kDebugMode) {
        print('즐겨찾기 개수 로딩 실패: $e');
      }
    }
  }

  Future<void> _toggleFavorite(MoodEntryModel entry) async {
    try {
      final success = await MoodService.toggleFavorite(entry.id);
      if (success) {
        await _loadMoodEntries();
        await _loadFavoriteCount();
        
        final newState = !entry.isFavorite;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newState ? '즐겨찾기에 추가되었습니다' : '즐겨찾기에서 제거되었습니다',
              ),
              backgroundColor: const Color(0xFFEC407A),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('즐겨찾기 변경에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('즐겨찾기 토글 중 오류: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showMoodEntryDialog({MoodEntryModel? existingEntry}) async {
    final result = await showDialog<MoodEntryModel>(
      context: context,
      builder: (context) => MoodEntryDialog(
        currentUser: widget.currentUser,
        existingEntry: existingEntry,
      ),
    );

    if (result != null) {
      await _loadMoodEntries();
    }
  }

  Future<void> _deleteMoodEntry(MoodEntryModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '삭제 확인',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정말로 이 감정일기를 삭제하시겠어요?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.mood.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.mood.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        entry.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (entry.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.content.length > 50 
                          ? '${entry.content.substring(0, 50)}...'
                          : entry.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ 삭제된 일기는 복구할 수 없습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '삭제',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await MoodService.deleteMoodEntry(entry.id);
        if (success) {
          await _loadMoodEntries();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('감정일기가 삭제되었습니다'),
                backgroundColor: const Color(0xFFEC407A),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('삭제에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('감정일기 삭제 중 오류: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 중 오류가 발생했습니다: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadMoodEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '감정일기',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        actions: [
          SimpleThemeToggle(size: 20),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoodStatisticsPage(currentUser: widget.currentUser),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.getPrimaryPink(ThemeService().isDarkModeActive(context)),
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('전체'),
                      if (_groupedEntries.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_groupedEntries.length}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, size: 16),
                      const SizedBox(width: 4),
                      const Text('즐겨찾기'),
                      if (_favoriteCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_favoriteCount',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        child: Column(
          children: [
            _buildWelcomeHeader(),
            _buildMonthSelector(),
            Expanded(
              child: _isLoading ? _buildLoadingWidget() : _buildEntriesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMoodEntryDialog(),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('기록 작성'),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final isDark = ThemeService().isDarkModeActive(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? AppColors.darkCardBackground 
            : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? AppColors.darkBorder 
              : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getPrimaryPink(isDark).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.favorite,
              color: AppColors.getPrimaryPink(isDark),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 감정을 기록해보세요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '소중한 순간들을 간직하고 패턴을 발견해보세요',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final isDark = ThemeService().isDarkModeActive(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(
              Icons.chevron_left,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          GestureDetector(
            onTap: () {
              // 월 선택 기능이 있다면 여기에 추가
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.darkSurfaceColor 
                    : AppColors.lightSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark 
                      ? AppColors.darkBorder 
                      : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedYear}년 ${_selectedMonth}월',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFEC407A),
      ),
    );
  }

  Widget _buildEntriesList() {
    if (_groupedEntries.isEmpty) {
      return _buildEmptyState();
    }

    // 날짜별로 정렬 (최신 날짜가 위로)
    final sortedDates = _groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final entries = _groupedEntries[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        return _buildDateGroup(date, entries);
      },
    );
  }

  Widget _buildDateGroup(DateTime date, List<MoodEntryModel> entries) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEC407A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: const Color(0xFFEC407A),
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.month}월 ${date.day}일 (${_getDayOfWeek(date)})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEC407A),
                  ),
                ),
                const Spacer(),
                Text(
                  '${entries.length}개',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFEC407A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 해당 날짜의 감정일기들
          ...entries.map((entry) => _buildEntryCard(entry)),
        ],
      ),
    );
  }

  Widget _buildEntryCard(MoodEntryModel entry) {
    final isDark = ThemeService().isDarkModeActive(context);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: entry.isFavorite 
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: entry.isFavorite 
                ? const Color(0xFFFFD700).withOpacity(0.2)
                : (isDark ? Colors.black26 : Colors.grey.withOpacity(0.1)),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showMoodEntryDialog(existingEntry: entry),
        onLongPress: () => _showEntryOptions(entry),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.mood.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.mood.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (entry.isFavorite) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star,
                              size: 16,
                              color: const Color(0xFFFFD700),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            entry.formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      if (entry.content.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          entry.content.length > 100 
                              ? '${entry.content.substring(0, 100)}...'
                              : entry.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (entry.activities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: entry.activities.take(3).map((activity) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC407A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '🏃 $activity',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFFEC407A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList()
                            ..addAll(entry.activities.length > 3 
                                ? [Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      '+${entry.activities.length - 3}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  )]
                                : []),
                        ),
                      ],
                      // 이미지 표시
                      if (entry.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.image,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '사진 ${entry.imageUrls.length}장',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // 즐겨찾기 버튼
                IconButton(
                  onPressed: () => _toggleFavorite(entry),
                  icon: Icon(
                    entry.isFavorite ? Icons.star : Icons.star_border,
                    color: entry.isFavorite 
                        ? const Color(0xFFFFD700)
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                  tooltip: entry.isFavorite ? '즐겨찾기 제거' : '즐겨찾기 추가',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryOptions(MoodEntryModel entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 일기 미리보기
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          entry.mood.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.mood.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                '${entry.formattedDate} ${entry.formattedTime}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 옵션 버튼들
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showMoodEntryDialog(existingEntry: entry);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC407A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '수정하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMoodEntry(entry);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '삭제하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showOnlyFavorites ? Icons.star_outline : Icons.sentiment_satisfied_alt,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '$_selectedYear년 $_selectedMonth월',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlyFavorites 
                  ? '즐겨찾기한 감정일기가 없어요'
                  : '아직 감정일기가 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlyFavorites 
                  ? '특별한 감정일기에 ⭐을 눌러 즐겨찾기로 만들어보세요!'
                  : '첫 번째 감정일기를 작성해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return weekdays[date.weekday % 7];
  }
}
