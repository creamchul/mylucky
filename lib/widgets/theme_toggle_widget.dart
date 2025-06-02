import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeToggleWidget extends StatefulWidget {
  final bool showLabel;
  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;

  const ThemeToggleWidget({
    super.key,
    this.showLabel = true,
    this.iconSize = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<ThemeToggleWidget> createState() => _ThemeToggleWidgetState();
}

class _ThemeToggleWidgetState extends State<ThemeToggleWidget>
    with TickerProviderStateMixin {
  late ThemeService _themeService;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _themeService.addListener(_onThemeChanged);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _toggleTheme() {
    _animationController.forward().then((_) {
      _themeService.toggleDarkMode();
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeService.isDarkModeActive(context);
    final theme = Theme.of(context);
    
    if (widget.showLabel) {
      return _buildWithLabel(isDark, theme);
    } else {
      return _buildIconOnly(isDark, theme);
    }
  }

  Widget _buildWithLabel(bool isDark, ThemeData theme) {
    return InkWell(
      onTap: _toggleTheme,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 6.28319, // 2π radians
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    size: widget.iconSize,
                    color: widget.activeColor ?? 
                           (isDark ? Colors.amber : theme.colorScheme.primary),
                  ),
                );
              },
            ),
            if (widget.showLabel) ...[
              const SizedBox(width: 12),
              Text(
                isDark ? '다크모드' : '라이트모드',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconOnly(bool isDark, ThemeData theme) {
    return IconButton(
      onPressed: _toggleTheme,
      icon: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 6.28319, // 2π radians
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: widget.iconSize,
              color: widget.activeColor ?? 
                     (isDark ? Colors.amber : theme.colorScheme.primary),
            ),
          );
        },
      ),
      tooltip: isDark ? '라이트모드로 변경' : '다크모드로 변경',
    );
  }
}

/// 간단한 테마 토글 버튼
class SimpleThemeToggle extends StatelessWidget {
  final double size;
  
  const SimpleThemeToggle({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return ThemeToggleWidget(
      showLabel: false,
      iconSize: size,
    );
  }
}

/// 설정용 테마 선택 위젯 (시스템/라이트/다크)
class ThemeSelectionWidget extends StatefulWidget {
  const ThemeSelectionWidget({super.key});

  @override
  State<ThemeSelectionWidget> createState() => _ThemeSelectionWidgetState();
}

class _ThemeSelectionWidgetState extends State<ThemeSelectionWidget> {
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '테마 설정',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildThemeOption(
            context,
            ThemeMode.system,
            '시스템 설정 따라가기',
            Icons.smartphone,
            '디바이스 설정에 따라 자동으로 변경됩니다',
          ),
          _buildThemeOption(
            context,
            ThemeMode.light,
            '라이트모드',
            Icons.light_mode,
            '항상 밝은 테마를 사용합니다',
          ),
          _buildThemeOption(
            context,
            ThemeMode.dark,
            '다크모드',
            Icons.dark_mode,
            '항상 어두운 테마를 사용합니다',
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    String title,
    IconData icon,
    String description,
  ) {
    final theme = Theme.of(context);
    final isSelected = _themeService.themeMode == mode;
    
    return InkWell(
      onTap: () => _themeService.setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
} 