import 'package:flutter/material.dart';

class FocusCategoryModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDefault;
  final bool isActive;
  final bool isFavorite;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FocusCategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isActive = true,
    this.isFavorite = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FocusCategoryModel.fromMap(Map<String, dynamic> map) {
    return FocusCategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.category.codePoint,
        fontFamily: map['iconFontFamily'] ?? Icons.category.fontFamily,
      ),
      color: Color(map['colorValue'] ?? Colors.blue.value),
      isDefault: map['isDefault'] ?? false,
      isActive: map['isActive'] ?? true,
      isFavorite: map['isFavorite'] ?? false,
      order: map['order'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'isDefault': isDefault,
      'isActive': isActive,
      'isFavorite': isFavorite,
      'order': order,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  FocusCategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    bool? isDefault,
    bool? isActive,
    bool? isFavorite,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FocusCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FocusCategoryModel(id: $id, name: $name, description: $description, isDefault: $isDefault, isActive: $isActive, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusCategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // 기본 카테고리들
  static List<FocusCategoryModel> getDefaultCategories() {
    final now = DateTime.now();
    return [
      FocusCategoryModel(
        id: 'work',
        name: '업무',
        description: '',
        icon: Icons.work,
        color: Colors.blue,
        isDefault: true,
        order: 0,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'study',
        name: '공부',
        description: '',
        icon: Icons.school,
        color: Colors.green,
        isDefault: true,
        order: 1,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'exercise',
        name: '운동',
        description: '',
        icon: Icons.fitness_center,
        color: Colors.orange,
        isDefault: true,
        order: 2,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'reading',
        name: '독서',
        description: '',
        icon: Icons.menu_book,
        color: Colors.purple,
        isDefault: true,
        order: 3,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'creative',
        name: '창작',
        description: '',
        icon: Icons.palette,
        color: Colors.pink,
        isDefault: true,
        order: 4,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'meditation',
        name: '명상',
        description: '',
        icon: Icons.spa,
        color: Colors.teal,
        isDefault: true,
        order: 5,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'personal',
        name: '개인',
        description: '',
        icon: Icons.person,
        color: Colors.indigo,
        isDefault: true,
        order: 6,
        createdAt: now,
        updatedAt: now,
      ),
      FocusCategoryModel(
        id: 'other',
        name: '기타',
        description: '',
        icon: Icons.more_horiz,
        color: Colors.grey,
        isDefault: true,
        order: 7,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // 아이콘 선택 옵션들
  static List<IconData> getAvailableIcons() {
    return [
      Icons.work,
      Icons.school,
      Icons.fitness_center,
      Icons.menu_book,
      Icons.palette,
      Icons.spa,
      Icons.person,
      Icons.computer,
      Icons.music_note,
      Icons.camera_alt,
      Icons.restaurant,
      Icons.home,
      Icons.car_repair,
      Icons.shopping_cart,
      Icons.favorite,
      Icons.star,
      Icons.lightbulb,
      Icons.build,
      Icons.sports_soccer,
      Icons.games,
      Icons.travel_explore,
      Icons.science,
      Icons.psychology,
      Icons.language,
      Icons.more_horiz,
    ];
  }

  // 색상 선택 옵션들
  static List<Color> getAvailableColors() {
    return [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.red,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lime,
      Colors.brown,
      Colors.blueGrey,
      Colors.grey,
    ];
  }
} 