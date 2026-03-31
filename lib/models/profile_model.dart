class Profile {
  final String id;
  final String? email; // Added
  final String? firstName; // Added
  final String? lastName; // Added
  final String? userType; // Added (e.g., 'student', 'admin')
  final String? phone; // Added
  final DateTime createdAt;
  final String? avatarUrl;

  // Student specific fields
  final String? studentOption; // Added (e.g., 'Étudiant simple', 'Responsable d\'amphi', 'Membre BUE')
  final String? faculty; // Added
  final String? filiere; // Renamed from 'field' to 'filiere'
  final String? level; // Added (e.g., L1, M2)
  final String? matricule;
  final DateTime? dateOfBirth; // Added

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  // Admin specific fields
  final String? adminOption; // Added (e.g., 'Enseignant', 'Autre')
  final String? otherRole; // Added
  final String? teachingDomain; // Added
  final List<String>? taughtSubjects; // Added

  Profile({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.userType,
    this.phone,
    required this.createdAt,
    this.avatarUrl,
    this.studentOption,
    this.faculty,
    this.filiere,
    this.level,
    this.matricule,
    this.dateOfBirth,
    this.adminOption,
    this.otherRole,
    this.teachingDomain,
    this.taughtSubjects,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      userType: json['user_type'] as String?,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      avatarUrl: json['avatar_url'] as String?,
      studentOption: json['student_option'] as String?,
      faculty: json['faculty'] as String?,
      filiere: json['filiere'] as String?,
      level: json['level'] as String?,
      matricule: json['matricule'] as String?,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      adminOption: json['admin_option'] as String?,
      otherRole: json['other_role'] as String?,
      teachingDomain: json['teaching_domain'] as String?,
      taughtSubjects: (json['taught_subjects'] as List?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
      'student_option': studentOption,
      'faculty': faculty,
      'filiere': filiere,
      'level': level,
      'matricule': matricule,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'admin_option': adminOption,
      'other_role': otherRole,
      'teaching_domain': teachingDomain,
      'taught_subjects': taughtSubjects,
    };
  }

  Profile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? userType,
    String? phone,
    DateTime? createdAt,
    String? avatarUrl,
    String? studentOption,
    String? faculty,
    String? filiere,
    String? level,
    String? matricule,
    DateTime? dateOfBirth,
    String? adminOption,
    String? otherRole,
    String? teachingDomain,
    List<String>? taughtSubjects,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userType: userType ?? this.userType,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      studentOption: studentOption ?? this.studentOption,
      faculty: faculty ?? this.faculty,
      filiere: filiere ?? this.filiere,
      level: level ?? this.level,
      matricule: matricule ?? this.matricule,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      adminOption: adminOption ?? this.adminOption,
      otherRole: otherRole ?? this.otherRole,
      teachingDomain: teachingDomain ?? this.teachingDomain,
      taughtSubjects: taughtSubjects ?? this.taughtSubjects,
    );
  }
}
