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
    DateTime? startDate,
    DateTime? dueDate,
    Duration? estimatedTime,
    RepeatPattern? repeatPattern,
    List<String> tags = const [],
    int? targetCount,
    bool hasReminder = false,
    DateTime? reminderTime,
    int? reminderMinutesBefore,
    bool showUntilCompleted = true,
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
        startDate: startDate,
        dueDate: dueDate,
        estimatedTime: estimatedTime,
        repeatPattern: repeatPattern,
        tags: tags,
        targetCount: targetCount,
        hasReminder: hasReminder,
        reminderTime: reminderTime,
        reminderMinutesBefore: reminderMinutesBefore,
        showUntilCompleted: showUntilCompleted,
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

      // 필터링 (시작일이 미래인 할일도 포함 - 전체 리스트에서는 표시)
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
        // 완료된 할일은 여기서 제외 (completedTodayTodos에서 별도 처리)
        if (todo.isCompleted) {
          return false;
        }
        
        // 시작 전인 할일은 제외 (시작일이 미래인 경우)
        if (todo.isBeforeStart) {
          return false;
        }
        
        // 일회성: showUntilCompleted 옵션에 따라 처리
        if (todo.type == TodoType.oneTime) {
          if (todo.isStarted) {
            if (todo.showUntilCompleted) {
              // 완료할 때까지 표시: 시작일이 지났으면 계속 표시
              return true;
            } else {
              // 기간 내에만 표시: 시작일~마감일 사이에만 표시
              if (todo.dueDate == null) {
                // 마감일이 없으면 시작일 이후부터 완료될 때까지 계속 표시
                return true;
              } else {
                // 마감일이 있으면 마감일까지 표시
                final todayDate = DateTime(today.year, today.month, today.day);
                final dueOnlyDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
                
                return !dueOnlyDate.isBefore(todayDate);
              }
            }
          }
          return false;
        }
        
        // 습관: 시작일이 지났고 마감일이 아직 지나지 않았으면 표시
        if (todo.type == TodoType.habit) {
          // 시작일이 지나지 않았으면 표시하지 않음
          if (!todo.isStarted) {
            return false;
          }
          
          // 마감일이 있고 이미 지났으면 표시하지 않음
          if (todo.dueDate != null) {
            final todayDate = DateTime(today.year, today.month, today.day);
            final dueOnlyDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
            
            if (dueOnlyDate.isBefore(todayDate)) {
              return false; // 마감일이 이미 지났음
            }
          }
          
          // 반복 패턴에 따라 오늘 해당하는지 확인
          return _isTodoForToday(todo);
        }
        
        // 오늘 기한인 할일 (시작일이 지났거나 오늘인 경우)
        if (todo.isDueToday && todo.isStarted) return true;
        
        // 반복 할일 체크 (시작일이 지났고 마감일이 아직 지나지 않은 경우)
        if (todo.isRepeating && todo.isStarted) {
          switch (todo.type) {
            case TodoType.repeat:
              // 마감일이 있고 이미 지났으면 표시하지 않음
              if (todo.dueDate != null) {
                final todayDate = DateTime(today.year, today.month, today.day);
                final dueOnlyDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
                
                if (dueOnlyDate.isBefore(todayDate)) {
                  return false; // 마감일이 이미 지났음
                }
              }
              
              // 반복 패턴에 따라 오늘 해당하는지 확인
              return _isTodoForToday(todo);
            case TodoType.habit:
              // 이미 위에서 처리됨
              return false;
            default:
              return false;
          }
        }
        return false;
      }).toList();

      // 오늘 완료된 투두들도 포함 (모든 타입)
      final completedTodayTodos = allTodos.where((todo) {
        if (todo.isCompleted && todo.completedAt != null) {
          final completedDate = todo.completedAt!;
          final isCompletedToday = completedDate.year == today.year && 
                                   completedDate.month == today.month && 
                                   completedDate.day == today.day;
          
          if (isCompletedToday) {
            // 모든 타입의 오늘 완료된 할일 포함 (일회성, 반복, 습관)
              return true;
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
      
      // 습관 타입인 경우 습관 추적기에 먼저 기록 - 임시 비활성화
      // Map<String, dynamic> habitResult = {};
      int finalStreak = todo.streak;
      int finalBestStreak = todo.bestStreak;
      
      if (todo.isHabit) {
        // 간단한 연속 달성 계산
        finalStreak = todo.streak + 1;
        if (finalStreak > finalBestStreak) {
          finalBestStreak = finalStreak;
        }
        
        if (kDebugMode) {
          print('TodoService: 습관 연속 달성 계산 - 연속 달성: $finalStreak일');
        }
        
        // HabitService 호출 비활성화
        // try {
        //   habitResult = await HabitService.recordHabitCompletion(
        //     userId: userId,
        //     habitId: todoId,
        //     currentUser: currentUser,
        //     date: now,
        //   );
        //   
        //   // 습관 추적기의 통계를 기반으로 연속 달성 계산
        //   final habitStats = habitResult['stats'] as HabitStats?;
        //   if (habitStats != null) {
        //     finalStreak = habitStats.currentStreak;
        //     finalBestStreak = habitStats.bestStreak;
        //   }
        //   
        //   if (kDebugMode) {
        //     print('TodoService: 습관 추적기 기록 완료 - 연속 달성: $finalStreak일');
        //   }
        // } catch (e) {
        //   if (kDebugMode) {
        //     print('TodoService: 습관 기록 실패 - $e');
        //   }
        //   // 습관 기록 실패해도 투두 완료는 진행
        // }
      }
      
      // 투두 완료 처리 (습관 추적기 통계 기반으로 streak 설정)
      final completedTodo = todo.copyWith(
        isCompleted: true,
        completedAt: now,
        // 습관의 경우 incrementHabitProgress에서 이미 currentCount가 증가되었으므로 다시 증가시키지 않음
        currentCount: todo.isHabit ? todo.currentCount : (todo.currentCount + 1),
        streak: finalStreak,
        bestStreak: finalBestStreak,
      );

      todos[todoIndex] = completedTodo;
      await _saveTodosToLocal(userId, todos);

      // Firebase 업데이트 (웹이 아닌 경우) - 임시 비활성화
      // if (!kIsWeb) {
      //   try {
      //     await FirebaseService.updateTodo(completedTodo);
      //   } catch (e) {
      //     if (kDebugMode) {
      //       print('TodoService: Firebase 업데이트 실패 - $e');
      //     }
      //   }
      // }

      // 반복 할일 다음 인스턴스 생성 비활성화 (일회성처럼 처리)
      // if (todo.isRepeating) {
      //   try {
      //     await createNextRepeatInstance(completedTodo);
      //     if (kDebugMode) {
      //       print('TodoService: 다음 반복 인스턴스 생성 완료');
      //     }
      //   } catch (e) {
      //     if (kDebugMode) {
      //       print('TodoService: 다음 반복 인스턴스 생성 실패 - $e');
      //     }
      //   }
      // }

      // 습관 타입인 경우 습관 완료 보상 지급 - 임시 비활성화
      if (completedTodo.isHabit) {
        // 간단한 포인트 지급
        final updatedUser = currentUser.copyWith(
          rewardPoints: currentUser.rewardPoints + completedTodo.difficultyPoints,
        );
        
        if (kDebugMode) {
          print('TodoService: 습관 완료 - ${completedTodo.difficultyPoints}P 지급');
        }
        
        return {
          'todo': completedTodo,
          'user': updatedUser,
          'pointsEarned': completedTodo.difficultyPoints,
          'isHabit': true,
          'isCompleted': true,
          'progressText': completedTodo.habitProgressText,
        };
      }

      // 일반 투두 보상 지급 - RewardService 호출 비활성화
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + completedTodo.difficultyPoints,
      );

      // try {
      //   rewardResult = await RewardService.giveTodoReward(
      //     currentUser: currentUser,
      //     todo: completedTodo,
      //   );
      // } catch (e) {
      //   if (kDebugMode) {
      //     print('TodoService: 보상 지급 실패 - $e');
      //   }
      // }

      if (kDebugMode) {
        print('TodoService: 투두 완료 처리 완료 - ${completedTodo.title}');
      }

      return {
        'todo': completedTodo,
        'user': updatedUser,
        'pointsEarned': completedTodo.difficultyPoints,
        'isHabit': false,
        'isCompleted': true,
        'progressText': completedTodo.isHabit ? completedTodo.habitProgressText : '',
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
      if (kDebugMode) {
        print('TodoService: 습관 진행률 증가 시작 - userId: $userId, todoId: $todoId');
      }
      
      final todos = await _loadTodosFromLocal(userId);
      if (kDebugMode) {
        print('TodoService: 로컬 투두 목록 로드 완료 - ${todos.length}개');
      }
      
      final todoIndex = todos.indexWhere((todo) => todo.id == todoId);
      
      if (todoIndex == -1) {
        if (kDebugMode) {
          print('TodoService: 투두를 찾을 수 없음 - todoId: $todoId');
          print('TodoService: 사용 가능한 투두 ID들: ${todos.map((t) => t.id).toList()}');
        }
        throw Exception('투두를 찾을 수 없습니다: $todoId');
      }

      final todo = todos[todoIndex];
      if (kDebugMode) {
        print('TodoService: 투두 찾음 - title: ${todo.title}, type: ${todo.type}, isHabit: ${todo.isHabit}');
      }
      
      if (!todo.isHabit) {
        if (kDebugMode) {
          print('TodoService: 습관 타입이 아님 - type: ${todo.type}');
        }
        throw Exception('습관 타입이 아닙니다: $todoId');
      }

      if (todo.isCompleted) {
        if (kDebugMode) {
          print('TodoService: 이미 완료된 습관 - isCompleted: ${todo.isCompleted}');
        }
        throw Exception('이미 완료된 습관입니다: $todoId');
      }

      final newCount = todo.currentCount + 1;
      final targetCount = todo.effectiveTargetCount;
      
      if (kDebugMode) {
        print('TodoService: 진행률 계산 - currentCount: ${todo.currentCount}, newCount: $newCount, targetCount: $targetCount');
      }
      
      // 목표 달성 시 자동 완료 처리
      if (newCount >= targetCount) {
        if (kDebugMode) {
          print('TodoService: 습관 목표 달성! 자동 완료 처리 - ${todo.title}');
        }
        
        // 완료 처리를 위해 먼저 진행률을 업데이트 (목표 횟수로 제한)
        final updatedTodo = todo.copyWith(
          currentCount: targetCount, // 목표 초과하지 않도록 제한
          updatedAt: DateTime.now(),
        );

        todos[todoIndex] = updatedTodo;
        await _saveTodosToLocal(userId, todos);
        
        // 완료 처리 호출
        return await completeTodo(
          userId: userId,
          todoId: todoId,
          currentUser: currentUser,
        );
      }
      
      // 진행률만 업데이트 (완료 처리 없음)
      final updatedTodo = todo.copyWith(
        currentCount: newCount,
        updatedAt: DateTime.now(),
      );

      todos[todoIndex] = updatedTodo;
      await _saveTodosToLocal(userId, todos);
      
      if (kDebugMode) {
        print('TodoService: 로컬 저장 완료');
      }

      // Firebase 업데이트 (웹이 아닌 경우) - 임시 비활성화
      // if (!kIsWeb) {
      //   try {
      //     await FirebaseService.updateTodo(updatedTodo);
      //     if (kDebugMode) {
      //       print('TodoService: Firebase 업데이트 완료');
      //     }
      //   } catch (e) {
      //     if (kDebugMode) {
      //       print('TodoService: Firebase 업데이트 실패 - $e');
      //     }
      //     // Firebase 실패는 무시하고 계속 진행
      //   }
      // }

      if (kDebugMode) {
        print('TodoService: 습관 진행률 업데이트 - ${updatedTodo.title} ($newCount/$targetCount)');
      }

      final result = {
        'todo': updatedTodo,
        'user': currentUser,
        'pointsEarned': 0,
        'isCompleted': false,
        'progress': updatedTodo.habitProgress,
        'progressText': updatedTodo.habitProgressText,
      };
      
      if (kDebugMode) {
        print('TodoService: 습관 진행률 증가 완료 - progress: ${updatedTodo.habitProgress}, progressText: ${updatedTodo.habitProgressText}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 습관 진행률 증가 실패 - $e');
        print('TodoService: 에러 스택 트레이스: ${StackTrace.current}');
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
    TodoType? type,
    TodoCategory? category,
    Priority? priority,
    Difficulty? difficulty,
    DateTime? startDate,
    DateTime? dueDate,
    Duration? estimatedTime,
    RepeatPattern? repeatPattern,
    List<String>? tags,
    int? targetCount,
    bool? hasReminder,
    DateTime? reminderTime,
    int? reminderMinutesBefore,
    bool? showUntilCompleted,
    bool clearStartDate = false,
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
        type: type,
        category: category,
        priority: priority,
        difficulty: difficulty,
        startDate: startDate,
        dueDate: dueDate,
        estimatedTime: estimatedTime,
        repeatPattern: repeatPattern,
        tags: tags,
        targetCount: targetCount,
        hasReminder: hasReminder,
        reminderTime: reminderTime,
        reminderMinutesBefore: reminderMinutesBefore,
        showUntilCompleted: showUntilCompleted,
        clearStartDate: clearStartDate,
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
  // 습관 상태 관리 (다음날 전환)
  // ========================================

  /// 자정 전환 시 습관 상태 리셋 및 히스토리 저장
  static Future<Map<String, dynamic>> processDailyHabitReset(String userId) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      final habits = todos.where((todo) => todo.isHabit).toList();
      
      final yesterdayResults = <Map<String, dynamic>>[];
      final updatedHabits = <TodoItemModel>[];
      
      for (final habit in habits) {
        // 어제 결과 저장
        final yesterdayResult = {
          'id': habit.id,
          'title': habit.title,
          'targetCount': habit.effectiveTargetCount,
          'currentCount': habit.currentCount,
          'completionRate': habit.habitProgress,
          'isCompleted': habit.isCompleted,
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
        };
        yesterdayResults.add(yesterdayResult);
        
        // 연속 달성 일수 계산
        int newStreak = 0;
        int newBestStreak = habit.bestStreak;
        
        if (habit.isCompleted || habit.isHabitCompleted) {
          newStreak = habit.streak + 1;
          if (newStreak > newBestStreak) {
            newBestStreak = newStreak;
          }
        } else {
          newStreak = 0; // 목표 미달성 시 연속 기록 리셋
        }
        
        // 오늘을 위한 새로운 상태로 리셋
        final resetHabit = habit.copyWith(
          currentCount: 0,
          isCompleted: false,
          completedAt: null,
          streak: newStreak,
          bestStreak: newBestStreak,
          updatedAt: DateTime.now(),
        );
        
        updatedHabits.add(resetHabit);
      }
      
      // 업데이트된 습관들을 전체 투두 목록에 반영
      final updatedTodos = todos.map((todo) {
        if (todo.isHabit) {
          return updatedHabits.firstWhere((updated) => updated.id == todo.id);
        }
        return todo;
      }).toList();
      
      // 로컬에 저장
      await _saveTodosToLocal(userId, updatedTodos);
      
      // 어제 결과를 히스토리에 저장
      await _saveHabitHistory(userId, yesterdayResults);
      
      if (kDebugMode) {
        print('TodoService: 일일 습관 리셋 완료 - ${habits.length}개 습관 처리');
      }
      
      return {
        'processedHabits': habits.length,
        'yesterdayResults': yesterdayResults,
        'updatedHabits': updatedHabits,
      };
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 일일 습관 리셋 실패 - $e');
      }
      rethrow;
    }
  }
  
  /// 습관 히스토리 저장
  static Future<void> _saveHabitHistory(String userId, List<Map<String, dynamic>> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'habit_history_$userId';
      
      // 기존 히스토리 로드
      final existingHistoryJson = prefs.getString(historyKey);
      List<Map<String, dynamic>> history = [];
      
      if (existingHistoryJson != null) {
        final existingHistory = json.decode(existingHistoryJson) as List;
        history = existingHistory.cast<Map<String, dynamic>>();
      }
      
      // 새 결과 추가
      history.addAll(results);
      
      // 최근 30일만 보관 (성능 최적화)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      history = history.where((result) {
        final date = DateTime.parse(result['date']);
        return date.isAfter(thirtyDaysAgo);
      }).toList();
      
      // 저장
      await prefs.setString(historyKey, json.encode(history));
      
      if (kDebugMode) {
        print('TodoService: 습관 히스토리 저장 완료 - ${results.length}개 결과');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 습관 히스토리 저장 실패 - $e');
      }
    }
  }
  
  /// 습관 히스토리 조회
  static Future<List<Map<String, dynamic>>> getHabitHistory(String userId, {int days = 7}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyKey = 'habit_history_$userId';
      final historyJson = prefs.getString(historyKey);
      
      if (historyJson == null) return [];
      
      final history = json.decode(historyJson) as List;
      final results = history.cast<Map<String, dynamic>>();
      
      // 지정된 일수만큼 필터링
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final filteredResults = results.where((result) {
        final date = DateTime.parse(result['date']);
        return date.isAfter(cutoffDate);
      }).toList();
      
      // 날짜순 정렬 (최신순)
      filteredResults.sort((a, b) => b['date'].compareTo(a['date']));
      
      return filteredResults;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 습관 히스토리 조회 실패 - $e');
      }
      return [];
    }
  }
  
  /// 어제 습관 결과 요약 생성
  static Future<Map<String, dynamic>> getYesterdayHabitSummary(String userId) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String().split('T')[0];
      
      final history = await getHabitHistory(userId, days: 2);
      final yesterdayResults = history.where((result) => result['date'] == yesterdayStr).toList();
      
      if (yesterdayResults.isEmpty) {
        return {
          'hasResults': false,
          'message': '어제 습관 기록이 없습니다.',
        };
      }
      
      final totalHabits = yesterdayResults.length;
      final completedHabits = yesterdayResults.where((result) => result['isCompleted'] == true).length;
      final partialHabits = yesterdayResults.where((result) => 
        result['isCompleted'] == false && result['currentCount'] > 0).length;
      final missedHabits = yesterdayResults.where((result) => result['currentCount'] == 0).length;
      
      String summaryMessage = '';
      if (completedHabits == totalHabits) {
        summaryMessage = '🎉 어제 모든 습관을 완료했어요!';
      } else if (completedHabits > 0) {
        summaryMessage = '👍 어제 ${completedHabits}개 습관을 완료했어요!';
      } else if (partialHabits > 0) {
        summaryMessage = '😊 어제 ${partialHabits}개 습관을 시작했어요!';
      } else {
        summaryMessage = '😞 어제는 습관을 실행하지 못했어요. 오늘 다시 시작해보세요!';
      }
      
      return {
        'hasResults': true,
        'totalHabits': totalHabits,
        'completedHabits': completedHabits,
        'partialHabits': partialHabits,
        'missedHabits': missedHabits,
        'summaryMessage': summaryMessage,
        'results': yesterdayResults,
      };
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 어제 습관 요약 생성 실패 - $e');
      }
      return {
        'hasResults': false,
        'message': '어제 습관 요약을 불러올 수 없습니다.',
      };
    }
  }

  // ========================================
  // 유틸리티 메서드
  // ========================================

  /// 반복 할일이 오늘에 해당하는지 확인
  static bool _isTodoForToday(TodoItemModel todo) {
    // 습관의 경우 반복 패턴이 없으면 매일 표시 (기본 동작)
    if (todo.type == TodoType.habit && todo.repeatPattern == null) {
      return true;
    }
    
    if (todo.repeatPattern == null) return false;
    
    final today = DateTime.now();
    
    switch (todo.repeatPattern!.repeatType) {
      case RepeatType.daily:
        return true; // 매일 반복이므로 항상 해당
        
      case RepeatType.weekly:
        // 주간 반복: 오늘 요일이 선택된 요일에 포함되어야 함
        if (todo.repeatPattern!.weekdays != null) {
          return todo.repeatPattern!.weekdays!.contains(today.weekday);
        }
        return false;
        
      case RepeatType.monthly:
        // 월간 반복: 오늘 날짜가 선택된 날짜에 포함되어야 함
        if (todo.repeatPattern!.monthDays != null) {
          final todayDay = today.day;
          final lastDayOfMonth = DateTime(today.year, today.month + 1, 0).day;
          
          for (final day in todo.repeatPattern!.monthDays!) {
            if (day == 99 && todayDay == lastDayOfMonth) return true; // 마지막 날
            if (day == todayDay) return true;
          }
        }
        return false;
        
      case RepeatType.yearly:
        // 연간 반복: 오늘 월/일이 선택된 월/일에 포함되어야 함
        if (todo.repeatPattern!.yearMonths != null && todo.repeatPattern!.yearDays != null) {
          return todo.repeatPattern!.yearMonths!.contains(today.month) &&
                 todo.repeatPattern!.yearDays!.contains(today.day);
        }
        return false;
        
      case RepeatType.custom:
        // 사용자 정의: 생성일로부터 간격 계산
        if (todo.repeatPattern!.customInterval != null && todo.dueDate != null) {
          final interval = todo.repeatPattern!.customInterval!;
          final daysSinceCreation = today.difference(todo.createdAt).inDays;
          return daysSinceCreation % interval == 0;
        }
        return false;
    }
  }

  /// 반복 할일의 다음 인스턴스 생성 (내부 헬퍼 메서드)
  static TodoItemModel? _createNextRepeatInstance(TodoItemModel todo) {
    if (todo.repeatPattern == null) return null;
    
    final now = DateTime.now();
    DateTime? nextDueDate;
    
    switch (todo.repeatPattern!.repeatType) {
      case RepeatType.daily:
        // 매일 반복: 내일 날짜로 설정
        nextDueDate = DateTime(now.year, now.month, now.day + 1);
        break;
        
      case RepeatType.weekly:
        // 주간 반복: 다음 해당 요일 찾기
        if (todo.repeatPattern!.weekdays != null) {
          final weekdays = todo.repeatPattern!.weekdays!;
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
        
      case RepeatType.monthly:
        // 월간 반복: 다음 달 해당 날짜들 중 첫 번째
        if (todo.repeatPattern!.monthDays != null) {
          final monthDays = todo.repeatPattern!.monthDays!;
          final nextMonth = DateTime(now.year, now.month + 1, 1);
          for (final day in monthDays) {
            if (day == 99) {
              // 마지막 날
              final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
              nextDueDate = DateTime(nextMonth.year, nextMonth.month, lastDay);
              break;
            } else if (day <= DateTime(nextMonth.year, nextMonth.month + 1, 0).day) {
              nextDueDate = DateTime(nextMonth.year, nextMonth.month, day);
              break;
            }
          }
        }
        break;
        
      case RepeatType.yearly:
        // 연간 반복: 내년 같은 날짜
        if (todo.repeatPattern!.yearMonths != null && todo.repeatPattern!.yearDays != null) {
          final months = todo.repeatPattern!.yearMonths!;
          final days = todo.repeatPattern!.yearDays!;
          if (months.isNotEmpty && days.isNotEmpty) {
            nextDueDate = DateTime(now.year + 1, months.first, days.first);
          }
        }
        break;
        
      case RepeatType.custom:
        // 사용자 정의: N일 후
        if (todo.repeatPattern!.customInterval != null) {
          final interval = todo.repeatPattern!.customInterval!;
          nextDueDate = DateTime(now.year, now.month, now.day + interval);
        }
        break;
    }
    
    if (nextDueDate == null) return null;
    
    // 새로운 인스턴스 생성
    return todo.copyWith(
      id: 'todo_${DateTime.now().millisecondsSinceEpoch}',
      dueDate: nextDueDate,
      isCompleted: false,
      completedAt: null,
      currentCount: 0, // 습관 카운트 리셋
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 반복 할일 다음 인스턴스 생성
  static Future<TodoItemModel?> createNextRepeatInstance(TodoItemModel completedTodo) async {
    if (!completedTodo.isRepeating || !completedTodo.isCompleted) {
      return null;
    }

    try {
      TodoItemModel? nextTodo;
      
      if (completedTodo.type == TodoType.repeat) {
        nextTodo = _createNextRepeatInstance(completedTodo);
      } else if (completedTodo.type == TodoType.habit) {
        // 습관의 경우 매일 반복
        final now = DateTime.now();
        final nextDueDate = DateTime(now.year, now.month, now.day + 1);
        
        nextTodo = completedTodo.copyWith(
          id: 'todo_${DateTime.now().millisecondsSinceEpoch}',
          dueDate: nextDueDate,
          isCompleted: false,
          completedAt: null,
          currentCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      if (nextTodo == null) return null;

      // 로컬에 저장
      final todos = await _loadTodosFromLocal(completedTodo.userId);
      todos.add(nextTodo);
      await _saveTodosToLocal(completedTodo.userId, todos);

      if (kDebugMode) {
        print('TodoService: 반복 할일 다음 인스턴스 생성 완료 - ${nextTodo.title}');
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

  // ========================================
  // 태그 관리 메서드
  // ========================================

  /// 사용자의 모든 투두에서 사용된 태그 목록 조회
  static Future<List<String>> getAllTags(String userId) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      final tagSet = <String>{};
      
      // 모든 투두의 태그를 수집
      for (final todo in todos) {
        tagSet.addAll(todo.tags);
      }
      
      // 기본 추천 태그들도 포함 (사용자가 아직 태그를 사용하지 않은 경우를 위해)
      final defaultTags = [
        '업무', '개인', '공부', '운동', '건강', '취미', 
        '쇼핑', '여행', '독서', '요리', '청소', '미팅',
        '프로젝트', '중요', '긴급', '루틴'
      ];
      
      tagSet.addAll(defaultTags);
      
      // 알파벳/한글 순으로 정렬
      final sortedTags = tagSet.toList()..sort();
      
      if (kDebugMode) {
        print('TodoService: 태그 목록 조회 완료 - ${sortedTags.length}개 태그');
      }
      
      return sortedTags;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 태그 목록 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 자주 사용되는 태그 목록 조회 (사용 빈도순)
  static Future<List<String>> getPopularTags(String userId, {int limit = 10}) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      final tagCount = <String, int>{};
      
      // 태그 사용 빈도 계산
      for (final todo in todos) {
        for (final tag in todo.tags) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }
      
      // 사용 빈도순으로 정렬
      final sortedTags = tagCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final popularTags = sortedTags
          .take(limit)
          .map((entry) => entry.key)
          .toList();
      
      if (kDebugMode) {
        print('TodoService: 인기 태그 조회 완료 - ${popularTags.length}개 태그');
      }
      
      return popularTags;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 인기 태그 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 태그별 투두 개수 통계
  static Future<Map<String, int>> getTagStatistics(String userId) async {
    try {
      final todos = await _loadTodosFromLocal(userId);
      final tagCount = <String, int>{};
      
      for (final todo in todos) {
        for (final tag in todo.tags) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }
      
      if (kDebugMode) {
        print('TodoService: 태그 통계 조회 완료 - ${tagCount.length}개 태그');
      }
      
      return tagCount;
    } catch (e) {
      if (kDebugMode) {
        print('TodoService: 태그 통계 조회 실패 - $e');
      }
      return {};
    }
  }
} 