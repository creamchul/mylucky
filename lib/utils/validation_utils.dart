/// 유효성 검증 관련 유틸리티 함수들
class ValidationUtils {
  ValidationUtils._(); // Private constructor

  /// 닉네임 유효성 검증
  static ValidationResult validateNickname(String? nickname) {
    if (nickname == null || nickname.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        message: '닉네임을 입력해주세요.',
      );
    }

    final trimmed = nickname.trim();
    
    if (trimmed.length < 2) {
      return ValidationResult(
        isValid: false,
        message: '닉네임은 2자 이상이어야 합니다.',
      );
    }

    if (trimmed.length > 10) {
      return ValidationResult(
        isValid: false,
        message: '닉네임은 10자 이하여야 합니다.',
      );
    }

    // 특수문자 검증 (한글, 영문, 숫자, 기본 특수문자만 허용)
    final validPattern = RegExp(r'^[가-힣a-zA-Z0-9\s._-]+$');
    if (!validPattern.hasMatch(trimmed)) {
      return ValidationResult(
        isValid: false,
        message: '닉네임에는 한글, 영문, 숫자, 기본 특수문자(._-)만 사용할 수 있습니다.',
      );
    }

    // 금지어 검증
    final forbiddenWords = ['관리자', 'admin', '운영자', '시스템', 'system', '테스트', 'test'];
    for (final word in forbiddenWords) {
      if (trimmed.toLowerCase().contains(word)) {
        return ValidationResult(
          isValid: false,
          message: '사용할 수 없는 닉네임입니다.',
        );
      }
    }

    return ValidationResult(
      isValid: true,
      message: '사용 가능한 닉네임입니다.',
    );
  }

  /// 이메일 유효성 검증
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        message: '이메일을 입력해주세요.',
      );
    }

    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailPattern.hasMatch(email.trim())) {
      return ValidationResult(
        isValid: false,
        message: '올바른 이메일 형식이 아닙니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      message: '올바른 이메일 형식입니다.',
    );
  }

  /// 문자열 길이 검증
  static ValidationResult validateLength(
    String? text,
    int minLength,
    int maxLength, {
    String fieldName = '입력값',
  }) {
    if (text == null || text.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        message: '$fieldName을 입력해주세요.',
      );
    }

    final length = text.trim().length;

    if (length < minLength) {
      return ValidationResult(
        isValid: false,
        message: '$fieldName은 $minLength자 이상이어야 합니다.',
      );
    }

    if (length > maxLength) {
      return ValidationResult(
        isValid: false,
        message: '$fieldName은 $maxLength자 이하여야 합니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      message: '올바른 형식입니다.',
    );
  }

  /// 숫자 범위 검증
  static ValidationResult validateNumberRange(
    int? number,
    int min,
    int max, {
    String fieldName = '숫자',
  }) {
    if (number == null) {
      return ValidationResult(
        isValid: false,
        message: '$fieldName을 입력해주세요.',
      );
    }

    if (number < min) {
      return ValidationResult(
        isValid: false,
        message: '$fieldName은 $min 이상이어야 합니다.',
      );
    }

    if (number > max) {
      return ValidationResult(
        isValid: false,
        message: '$fieldName은 $max 이하여야 합니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      message: '올바른 범위입니다.',
    );
  }

  /// 필수 입력 검증
  static ValidationResult validateRequired(
    String? text, {
    String fieldName = '필수 입력값',
  }) {
    if (text == null || text.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        message: '$fieldName은 필수 입력사항입니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      message: '입력 완료',
    );
  }

  /// 날짜 유효성 검증
  static ValidationResult validateDate(DateTime? date) {
    if (date == null) {
      return ValidationResult(
        isValid: false,
        message: '날짜를 선택해주세요.',
      );
    }

    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final oneYearLater = now.add(const Duration(days: 365));

    if (date.isBefore(oneYearAgo)) {
      return ValidationResult(
        isValid: false,
        message: '너무 과거의 날짜입니다.',
      );
    }

    if (date.isAfter(oneYearLater)) {
      return ValidationResult(
        isValid: false,
        message: '너무 미래의 날짜입니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      message: '올바른 날짜입니다.',
    );
  }

  /// 비밀번호 강도 검증 (필요시 사용)
  static ValidationResult validatePasswordStrength(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult(
        isValid: false,
        message: '비밀번호를 입력해주세요.',
      );
    }

    if (password.length < 8) {
      return ValidationResult(
        isValid: false,
        message: '비밀번호는 8자 이상이어야 합니다.',
      );
    }

    if (password.length > 20) {
      return ValidationResult(
        isValid: false,
        message: '비밀번호는 20자 이하여야 합니다.',
      );
    }

    // 영문, 숫자, 특수문자 포함 검증
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    if (!hasLetter || !hasNumber || !hasSpecialChar) {
      return ValidationResult(
        isValid: false,
        message: '비밀번호는 영문, 숫자, 특수문자를 모두 포함해야 합니다.',
      );
    }

    return ValidationResult(
      isValid: true,
      message: '강력한 비밀번호입니다.',
    );
  }

  /// 여러 검증 결과 결합
  static ValidationResult combineResults(List<ValidationResult> results) {
    for (final result in results) {
      if (!result.isValid) {
        return result; // 첫 번째 오류 반환
      }
    }

    return ValidationResult(
      isValid: true,
      message: '모든 검증을 통과했습니다.',
    );
  }
}

/// 검증 결과를 담는 클래스
class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult({
    required this.isValid,
    required this.message,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, message: $message)';
  }
} 