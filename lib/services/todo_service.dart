import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/todo_item_model.dart';
import '../models/user_model.dart';
import '../models/habit_tracker_model.dart';
import 'firebase_service.dart';
import 'reward_service.dart';
import 'habit_service.dart';

/// 오늘의 루틴 관리 서비스
class TodoService {
  static const String _todosKey = 'user_todos';
  static const String _completedTodosKey = 'completed_todos';
  
  // ========================================
  // 로컬 저장 관리 (웹/모바일 통합)
  // ========================================
  
  /// 투두 목록을 로컬에 저장
  static Future<void> _saveTodosToLocal(String userId, List<TodoItemModel> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = todos.map((todo) => todo.toMap()).toList();
      await prefs.setString('${_todosKey}_$userId', json.encode(todosJson));
      
      if (kDebugMode) {
        print('TodoService: 투두 목록 로컬 저장 완료 (${todos.length}개)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 투두 목록 로컬 저장 실패 - $e');
      }
    }
  }
  
  /// 로컬에서 투두 목록 불러오기
  static Future<List<TodoItemModel>> _loadTodosFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getString('${_todosKey}_$userId');
      
      if (todosJson != null) {
        final List<dynamic> todosList = json.decode(todosJson);
        final todos = todosList.map((json) => TodoItemModel.fromMap(json)).toList();
        
        if (kDebugMode) {
          print('TodoService: 로컬에서 투두 목록 로드 완료 (${todos.length}개)');
        }
        
        return todos;
      }
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 로컬 투두 목록 로드 실패 - $e');
      }
    }
    
    return [];
  }

  // ========================================
  // 투두 CRUD 기능
  // ========================================
  
  /// 새 투두 아이템 생성
  static Future<TodoItemModel> createTodo({
    required String userId,
    required String title,
    String description = '',
    TodoType type = TodoType.oneTime,
    TodoCategory category = TodoCategory.personal,
    Priority priority = Priority.medium,
    Difficulty difficulty = Difficulty.medium,
    DateTime? dueDate,
    Duration? estimatedTime,
    RepeatPattern? repeatPattern,
    List<String> tags = const [],
    int? targetCount,
    bool hasReminder = false,
    DateTime? reminderTime,
    int? reminderMinutesBefore,
  }) async {
    try {
      final newTodo = TodoItemModel.create(
        userId: userId,
        title: title,
        description: description,
        type: type,
        category: category,
        priority: priority,
        difficulty: difficulty,
        dueDate: dueDate,
        estimatedTime: estimatedTime,
        repeatPattern: repeatPattern,
        tags: tags,
        targetCount: targetCount,
        hasReminder: hasReminder,
        reminderTime: reminderTime,
        reminderMinutesBefore: reminderMinutesBefore,
      );

      // 로컬 저장
      final existingTodos = await _loadTodosFromLocal(userId);
      existingTodos.add(newTodo);
      await _saveTodosToLocal(userId, existingTodos);

      // Firebase 저장 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.createTodo(newTodo);
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: Firebase 저장 실패, 로컬만 저장됨 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('TodoService: 새 투두 생성 완료 - ${newTodo.title}');
      }

      return newTodo;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 투두 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 투두 목록 조회
  static Future<List<TodoItemModel>> getTodos(String userId, {
    TodoCategory? category,
    bool? isCompleted,
    DateTime? date,
  }) async {
    try {
      List<TodoItemModel> todos = await _loadTodosFromLocal(userId);

      // Firebase에서도 가져오기 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          final firebaseTodos = await FirebaseService.getUserTodos(userId);
          // 로컬과 Firebase 데이터 병합 (중복 제거)
          final localIds = todos.map((t) => t.id).toSet();
          final newTodos = firebaseTodos.where((t) => !localIds.contains(t.id)).toList();
          todos.addAll(newTodos);
          
          // 병합된 데이터를 로컬에 저장
          if (newTodos.isNotEmpty) {
            await _saveTodosToLocal(userId, todos);
          }
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: Firebase 조회 실패, 로컬 데이터만 사용 - $e');
          }
        }
      }

      // 필터링
      if (category != null) {
        todos = todos.where((todo) => todo.category == category).toList();
      }
      
      if (isCompleted != null) {
        todos = todos.where((todo) => todo.isCompleted == isCompleted).toList();
      }

      if (date != null) {
        todos = todos.where((todo) {
          if (todo.dueDate == null) return false;
          final dueDate = todo.dueDate!;
          return dueDate.year == date.year && 
                 dueDate.month == date.month && 
                 dueDate.day == date.day;
        }).toList();
      }

      // 정렬 (우선순위 > 기한 > 생성일)
      todos.sort((a, b) {
        // 완료 여부로 먼저 정렬
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        
        // 우선순위로 정렬
        final priorityOrder = {Priority.high: 0, Priority.medium: 1, Priority.low: 2};
        final priorityCompare = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
        if (priorityCompare != 0) return priorityCompare;
        
        // 기한으로 정렬
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        } else if (a.dueDate != null) {
          return -1;
        } else if (b.dueDate != null) {
          return 1;
        }
        
        // 생성일로 정렬
        return b.createdAt.compareTo(a.createdAt);
      });

      if (kDebugMode) {
        print('TodoService: 투두 목록 조회 완료 (${todos.length}개)');
      }

      return todos;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 투두 목록 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 오늘의 할일 조회
  static Future<List<TodoItemModel>> getTodayTodos(String userId) async {
    try {
      final allTodos = await getTodos(userId);
      final today = DateTime.now();
      
      final todayTodos = allTodos.where((todo) {
        // 일회성: 완료 전까지 매일 노출
        if (todo.type == TodoType.oneTime) {
          return !todo.isCompleted;
        }
        
        // 오늘 기한인 할일 (미완료만)
        if (todo.isDueToday && !todo.isCompleted) return true;
        
        // 반복 할일 체크 (미완료이고 오늘이 해당 요일인 경우만)
        if (todo.isRepeating && !todo.isCompleted) {
          switch (todo.type) {
            case TodoType.daily:
            case TodoType.habit:
              // 매일 반복: 오늘 날짜인 경우만 표시
              return todo.isDueToday || todo.dueDate == null;
            case TodoType.weekly:
              // 주간 반복: 반복 요일에 오늘이 포함되어 있고 오늘 날짜인 경우만 표시
              if (todo.repeatPattern?.weekdays != null &&
                  todo.repeatPattern!.weekdays!.contains(today.weekday)) {
                return todo.isDueToday || todo.dueDate == null;
              }
              return false;
            default:
              return false;
          }
        }
        return false;
      }).toList();

      // 오늘 완료된 투두들도 포함 (일회성 + 반복 할일 모두)
      final completedTodayTodos = allTodos.where((todo) {
        if (todo.isCompleted && todo.completedAt != null) {
          final completedDate = todo.completedAt!;
          final isCompletedToday = completedDate.year == today.year && 
                                   completedDate.month == today.month && 
                                   completedDate.day == today.day;
          
          if (isCompletedToday) {
            // 일회성 투두는 항상 포함
            if (todo.type == TodoType.oneTime) {
              return true;
            }
            
            // 반복 할일도 오늘 완료된 것은 포함
            if (todo.isRepeating) {
              switch (todo.type) {
                case TodoType.daily:
                case TodoType.habit:
                  return true; // 매일 반복
                case TodoType.weekly:
                  // 주간 반복: 오늘이 반복 요일에 포함되어 있으면 포함
                  if (todo.repeatPattern?.weekdays != null &&
                      todo.repeatPattern!.weekdays!.contains(today.weekday)) {
                    return true;
                  }
                  return false;
                default:
                  return false;
              }
            }
          }
        }
        return false;
      }).toList();

      // 미완료 + 오늘 완료된 투두 모두 포함
      final result = [...todayTodos, ...completedTodayTodos];

      if (kDebugMode) {
        print('TodoService: 오늘의 할일 조회 완료 (${result.length}개)');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 오늘의 할일 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 투두 완료 처리
  static Future<Map<String, dynamic>> completeTodo({
    required String userId,
    required String todoId,
    required UserModel currentUser,
  }) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      final todoIndex = todos.indexWhere((todo) => todo.id == todoId);
      
      if (todoIndex == -1) {
        throw Exception('투두를 찾을 수 없습니다: $todoId');
      }

      final todo = todos[todoIndex];
      final now = DateTime.now();
      
      // 습관 타입인 경우 습관 추적기에 먼저 기록
      Map<String, dynamic> habitResult = {};
      int finalStreak = todo.streak;
      int finalBestStreak = todo.bestStreak;
      
      if (todo.isHabit) {
        try {
          habitResult = await HabitService.recordHabitCompletion(
            userId: userId,
            habitId: todoId,
            currentUser: currentUser,
            date: now,
          );
          
          // 습관 추적기의 통계를 기반으로 연속 달성 계산
          final habitStats = habitResult['stats'] as HabitStats?;
          if (habitStats != null) {
            finalStreak = habitStats.currentStreak;
            finalBestStreak = habitStats.bestStreak;
          }
          
          if (kDebugMode) {
            print('TodoService: 습관 추적기 기록 완료 - 연속 달성: $finalStreak일');
          }
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: 습관 기록 실패 - $e');
          }
          // 습관 기록 실패해도 투두 완료는 진행
        }
      }
      
      // 투두 완료 처리 (습관 추적기 통계 기반으로 streak 설정)
      final completedTodo = todo.copyWith(
        isCompleted: true,
        completedAt: now,
        currentCount: todo.currentCount + 1,
        streak: finalStreak,
        bestStreak: finalBestStreak,
      );

      todos[todoIndex] = completedTodo;
      await _saveTodosToLocal(userId, todos);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateTodo(completedTodo);
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      // 습관 타입인 경우 습관 완료 보상 지급
      if (completedTodo.isHabit) {
        try {
          final rewardResult = await HabitService.giveHabitCompletionReward(
            userId: userId,
            habitId: todoId,
            currentUser: habitResult['user'] ?? currentUser,
            streakDays: finalStreak,
          );
          
          if (kDebugMode) {
            print('TodoService: 습관 완료 보상 지급 - ${rewardResult['pointsEarned']}P');
          }
          
          return {
            'todo': completedTodo,
            'user': rewardResult['user'],
            'pointsEarned': rewardResult['pointsEarned'],
            'habitStats': habitResult['stats'],
            'isHabit': true,
          };
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: 습관 완료 보상 지급 실패 - $e');
          }
          // 보상 지급 실패해도 완료는 유지
        }
      }

      // 일반 투두 보상 지급
      Map<String, dynamic> rewardResult = {
        'user': currentUser,
        'pointsEarned': 0,
      };

      try {
        rewardResult = await RewardService.giveTodoReward(
          currentUser: currentUser,
          todo: completedTodo,
        );
      } catch (e) {
        if (kDebugMode) {
          print('TodoService: 보상 지급 실패 - $e');
        }
      }

      if (kDebugMode) {
        print('TodoService: 투두 완료 처리 완료 - ${completedTodo.title}');
      }

      return {
        'todo': completedTodo,
        'user': rewardResult['user'],
        'pointsEarned': rewardResult['pointsEarned'] ?? 0,
        'isHabit': false,
      };
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 투두 완료 처리 실패 - $e');
      }
      rethrow;
    }
  }

  /// 습관 진행률 증가 (목표 달성 시 자동 완료)
  static Future<Map<String, dynamic>> incrementHabitProgress({
    required String userId,
    required String todoId,
    required UserModel currentUser,
  }) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      final todoIndex = todos.indexWhere((todo) => todo.id == todoId);
      
      if (todoIndex == -1) {
        throw Exception('투두를 찾을 수 없습니다: $todoId');
      }

      final todo = todos[todoIndex];
      
      if (!todo.isHabit) {
        throw Exception('습관 타입이 아닙니다: $todoId');
      }

      if (todo.isCompleted) {
        throw Exception('이미 완료된 습관입니다: $todoId');
      }

      final newCount = todo.currentCount + 1;
      final targetCount = todo.effectiveTargetCount;
      
      // 진행률 업데이트
      final updatedTodo = todo.copyWith(
        currentCount: newCount,
        updatedAt: DateTime.now(),
      );

      todos[todoIndex] = updatedTodo;
      await _saveTodosToLocal(userId, todos);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateTodo(updatedTodo);
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('TodoService: 습관 진행률 업데이트 - ${updatedTodo.title} ($newCount/$targetCount)');
      }

      // 목표 달성 시 자동 완료 (이때 습관 추적기에 기록)
      if (newCount >= targetCount) {
        if (kDebugMode) {
          print('TodoService: 습관 목표 달성! 자동 완료 처리 - ${updatedTodo.title}');
        }
        
        return await completeTodo(
          userId: userId,
          todoId: todoId,
          currentUser: currentUser,
        );
      }

      return {
        'todo': updatedTodo,
        'user': currentUser,
        'pointsEarned': 0,
        'isCompleted': false,
        'progress': updatedTodo.habitProgress,
        'progressText': updatedTodo.habitProgressText,
      };
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 습관 진행률 증가 실패 - $e');
      }
      rethrow;
    }
  }

  /// 투두 수정
  static Future<TodoItemModel> updateTodo({
    required String userId,
    required String todoId,
    String? title,
    String? description,
    TodoCategory? category,
    Priority? priority,
    Difficulty? difficulty,
    DateTime? dueDate,
    Duration? estimatedTime,
    bool? hasReminder,
    DateTime? reminderTime,
    int? reminderMinutesBefore,
    bool clearDueDate = false,
    bool clearReminderTime = false,
  }) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      final todoIndex = todos.indexWhere((todo) => todo.id == todoId);
      
      if (todoIndex == -1) {
        throw Exception('투두를 찾을 수 없습니다: $todoId');
      }

      final updatedTodo = todos[todoIndex].copyWith(
        title: title,
        description: description,
        category: category,
        priority: priority,
        difficulty: difficulty,
        dueDate: dueDate,
        estimatedTime: estimatedTime,
        hasReminder: hasReminder,
        reminderTime: reminderTime,
        reminderMinutesBefore: reminderMinutesBefore,
        clearDueDate: clearDueDate,
        clearReminderTime: clearReminderTime,
      );

      todos[todoIndex] = updatedTodo;
      await _saveTodosToLocal(userId, todos);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateTodo(updatedTodo);
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('TodoService: 투두 수정 완료 - ${updatedTodo.title}');
      }

      return updatedTodo;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 투두 수정 실패 - $e');
      }
      rethrow;
    }
  }

  /// 투두 삭제
  static Future<void> deleteTodo({
    required String userId,
    required String todoId,
  }) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      todos.removeWhere((todo) => todo.id == todoId);
      await _saveTodosToLocal(userId, todos);

      // Firebase에서도 삭제 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.deleteTodo(todoId);
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: Firebase 삭제 실패 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('TodoService: 투두 삭제 완료 - $todoId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 투두 삭제 실패 - $e');
      }
      rethrow;
    }
  }

  /// 투두 완료 취소
  static Future<Map<String, dynamic>> uncompleteTodo({
    required String userId,
    required String todoId,
    required UserModel currentUser,
  }) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      final todoIndex = todos.indexWhere((todo) => todo.id == todoId);
      
      if (todoIndex == -1) {
        throw Exception('투두를 찾을 수 없습니다: $todoId');
      }

      final todo = todos[todoIndex];
      
      if (!todo.isCompleted) {
        throw Exception('완료되지 않은 투두입니다: $todoId');
      }

      // 습관 타입인 경우 습관 추적기에서 기록 제거 후 통계 재계산
      Map<String, dynamic> habitResult = {};
      int finalStreak = 0;
      int finalBestStreak = todo.bestStreak;
      
      if (todo.isHabit) {
        try {
          habitResult = await HabitService.removeHabitCompletion(
            userId: userId,
            habitId: todoId,
            date: todo.completedAt ?? DateTime.now(),
          );
          
          // 습관 추적기의 통계를 기반으로 연속 달성 재계산
          final habitStats = habitResult['stats'] as HabitStats?;
          if (habitStats != null) {
            finalStreak = habitStats.currentStreak;
            finalBestStreak = habitStats.bestStreak;
          }
          
          if (kDebugMode) {
            print('TodoService: 습관 완료 기록 제거 완료 - 연속 달성: $finalStreak일');
          }
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: 습관 기록 제거 실패 - $e');
          }
          // 습관 기록 제거 실패해도 투두 완료 취소는 진행
        }
      }

      // 투두 완료 취소 처리 (습관 추적기 통계 기반으로 streak 설정)
      final uncompletedTodo = todo.copyWith(
        isCompleted: false,
        completedAt: null,
        currentCount: todo.isHabit ? (todo.currentCount - 1).clamp(0, todo.effectiveTargetCount) : 0,
        streak: finalStreak,
        bestStreak: finalBestStreak,
        clearCompletedAt: true,
      );

      todos[todoIndex] = uncompletedTodo;
      await _saveTodosToLocal(userId, todos);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateTodo(uncompletedTodo);
        } catch (e) {
          if (kDebugMode) {
            print('TodoService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      // 포인트 차감 (보상 시스템에서 처리)
      Map<String, dynamic> rewardResult = {
        'user': currentUser,
        'pointsDeducted': 0,
      };

      try {
        rewardResult = await RewardService.deductTodoReward(
          currentUser: currentUser,
          todo: todo,
        );
      } catch (e) {
        if (kDebugMode) {
          print('TodoService: 포인트 차감 실패 - $e');
        }
      }

      if (kDebugMode) {
        print('TodoService: 투두 완료 취소 처리 완료 - ${uncompletedTodo.title}');
      }

      return {
        'todo': uncompletedTodo,
        'user': rewardResult['user'],
        'pointsDeducted': rewardResult['pointsDeducted'] ?? 0,
        'isHabit': uncompletedTodo.isHabit,
        'habitStats': habitResult['stats'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 투두 완료 취소 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 통계 및 분석
  // ========================================

  /// 사용자 투두 통계 조회
  static Future<Map<String, dynamic>> getTodoStats(String userId) async {
    try {
      final allTodos = await getTodos(userId);
      final completedTodos = allTodos.where((todo) => todo.isCompleted).toList();
      final pendingTodos = allTodos.where((todo) => !todo.isCompleted).toList();
      final overdueTodos = pendingTodos.where((todo) => todo.isOverdue).toList();
      
      // 카테고리별 통계
      final categoryStats = <TodoCategory, Map<String, int>>{};
      for (final category in TodoCategory.values) {
        final categoryTodos = allTodos.where((todo) => todo.category == category).toList();
        final categoryCompleted = categoryTodos.where((todo) => todo.isCompleted).toList();
        
        categoryStats[category] = {
          'total': categoryTodos.length,
          'completed': categoryCompleted.length,
          'pending': categoryTodos.length - categoryCompleted.length,
        };
      }

      // 이번 주 완료율
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final weekTodos = allTodos.where((todo) {
        if (todo.completedAt == null) return false;
        final completed = todo.completedAt!;
        return completed.isAfter(weekStart) && completed.isBefore(weekEnd.add(const Duration(days: 1)));
      }).toList();

      return {
        'totalTodos': allTodos.length,
        'completedTodos': completedTodos.length,
        'pendingTodos': pendingTodos.length,
        'overdueTodos': overdueTodos.length,
        'completionRate': allTodos.isEmpty ? 0.0 : (completedTodos.length / allTodos.length * 100),
        'categoryStats': categoryStats,
        'weeklyCompleted': weekTodos.length,
        'totalPoints': completedTodos.fold<int>(0, (sum, todo) => sum + todo.difficultyPoints),
      };
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 통계 조회 실패 - $e');
      }
      return {
        'totalTodos': 0,
        'completedTodos': 0,
        'pendingTodos': 0,
        'overdueTodos': 0,
        'completionRate': 0.0,
        'categoryStats': <TodoCategory, Map<String, int>>{},
        'weeklyCompleted': 0,
        'totalPoints': 0,
      };
    }
  }

  // ========================================
  // 유틸리티 메서드
  // ========================================

  /// 반복 할일 다음 인스턴스 생성
  static Future<TodoItemModel?> createNextRepeatInstance(TodoItemModel completedTodo) async {
    if (!completedTodo.isRepeating || !completedTodo.isCompleted) {
      return null;
    }

    try {
      final now = DateTime.now();
      DateTime? nextDueDate;

      switch (completedTodo.type) {
        case TodoType.daily:
        case TodoType.habit:
          // 매일 반복: 내일 날짜로 설정
          nextDueDate = DateTime(now.year, now.month, now.day + 1);
          break;
        case TodoType.weekly:
          if (completedTodo.repeatPattern?.weekdays != null) {
            final weekdays = completedTodo.repeatPattern!.weekdays!;
            final currentWeekday = now.weekday;
            
            // 다음 해당 요일 찾기
            int daysToAdd = 1;
            while (daysToAdd <= 7) {
              final nextDay = now.add(Duration(days: daysToAdd));
              final nextWeekday = nextDay.weekday;
              if (weekdays.contains(nextWeekday)) {
                nextDueDate = DateTime(nextDay.year, nextDay.month, nextDay.day);
                break;
              }
              daysToAdd++;
            }
          }
          break;
        default:
          return null;
      }

      if (nextDueDate == null) return null;

      final nextTodo = TodoItemModel.create(
        userId: completedTodo.userId,
        title: completedTodo.title,
        description: completedTodo.description,
        type: completedTodo.type,
        category: completedTodo.category,
        priority: completedTodo.priority,
        difficulty: completedTodo.difficulty,
        dueDate: nextDueDate,
        estimatedTime: completedTodo.estimatedTime,
        repeatPattern: completedTodo.repeatPattern,
        tags: completedTodo.tags,
        targetCount: completedTodo.targetCount,
        hasReminder: completedTodo.hasReminder,
        reminderTime: completedTodo.reminderTime,
        reminderMinutesBefore: completedTodo.reminderMinutesBefore,
      );

      // 로컬에 저장
      final todos = await _loadTodosFromLocal(completedTodo.userId);
      todos.add(nextTodo);
      await _saveTodosToLocal(completedTodo.userId, todos);

      if (kDebugMode) {
        print('TodoService: 반복 할일 다음 인스턴스 생성 완료 - ${nextTodo.title} (${nextDueDate.toString().split(' ')[0]})');
      }

      return nextTodo;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 반복 할일 생성 실패 - $e');
      }
      return null;
    }
  }

  /// 기존 미션 시스템과의 연동을 위한 어댑터
  static Future<List<String>> getTodayMissions(String userId) async {
    try {
      final todayTodos = await getTodayTodos(userId);
      return todayTodos.map((todo) => todo.title).toList();
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 오늘의 미션 조회 실패 - $e');
      }
      return [];
    }
  }
} 