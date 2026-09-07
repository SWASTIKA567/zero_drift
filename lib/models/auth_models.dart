class UserModel {
  final int? id;
  final String username;
  final String email;

  UserModel({
    this.id,
    required this.username,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}

class AuthTokens {
  final String access;
  final String refresh;

  AuthTokens({
    required this.access,
    required this.refresh,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      access: json['access']?.toString() ?? '',
      refresh: json['refresh']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': access,
      'refresh': refresh,
    };
  }
}

class AuthResponse {
  final UserModel? user;
  final AuthTokens? tokens;
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, List<String>>? fieldErrors;

  AuthResponse({
    this.user,
    this.tokens,
    required this.isSuccess,
    this.errorMessage,
    this.fieldErrors,
  });

  factory AuthResponse.success({UserModel? user, AuthTokens? tokens}) {
    return AuthResponse(
      user: user,
      tokens: tokens,
      isSuccess: true,
    );
  }

  factory AuthResponse.failure(String message, {Map<String, List<String>>? fieldErrors}) {
    return AuthResponse(
      isSuccess: false,
      errorMessage: message,
      fieldErrors: fieldErrors,
    );
  }

  factory AuthResponse.fromApiResponse(Map<String, dynamic> json) {
    UserModel? user;
    if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
      user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    }

    AuthTokens? tokens;
    if (json.containsKey('tokens') && json['tokens'] is Map<String, dynamic>) {
      tokens = AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>);
    } else if (json.containsKey('access') || json.containsKey('refresh')) {
      tokens = AuthTokens(
        access: json['access']?.toString() ?? '',
        refresh: json['refresh']?.toString() ?? '',
      );
    }

    return AuthResponse(
      user: user,
      tokens: tokens,
      isSuccess: true,
    );
  }
}
