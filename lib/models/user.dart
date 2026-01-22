import 'package:equatable/equatable.dart';

/// User model for local database
class User extends Equatable {
  final int? id;
  final String name;
  final int points;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    this.id,
    required this.name,
    required this.points,
    this.avatarUrl,
    this.phoneNumber,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create default user
  factory User.defaultUser() {
    final now = DateTime.now();
    return User(
      name: 'Player',
      points: 100,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      points: map['points'] as int,
      avatarUrl: map['avatar_url'] as String?,
      phoneNumber: map['phone_number'] as String?,
      email: map['email'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'points': points,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with updated fields
  User copyWith({
    int? id,
    String? name,
    int? points,
    String? avatarUrl,
    String? phoneNumber,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, points, avatarUrl, phoneNumber, email, createdAt, updatedAt];
}
