class DocumentModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String filiere;
  final String subject; // New field for the subject/UE
  final String? documentType; // Ex: Examen, TD, Cours, Fiche, Memoire
  final String? documentOrigin; // Responsable du cours ou origine
  final String? level; // New field for level (L1, L2, etc.)
  final String? academicYear; // New field for academic year (e.g., "2024-2025")
  final bool isPublic;
  final bool isDraft;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? pdfPath;
  final String previewHtml;
  final bool isSynced;
  final bool syncPending;
  final bool isOffline; // ADDED

  DocumentModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.filiere,
    required this.subject, // Make subject required
    this.documentType,
    this.documentOrigin,
    this.level,
    this.academicYear,
    this.isPublic = true,
    this.isDraft = false,
    required this.createdAt,
    required this.updatedAt,
    this.pdfPath,
    this.previewHtml = '',
    this.isSynced = false,
    this.syncPending = false,
    this.isOffline = false, // ADDED
  });

  // Constructor for Supabase JSON (or general JSON)
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      filiere: json['filiere'] as String,
      subject: json['subject'] as String, // Parse subject
      documentType: json['document_type'] as String?,
      documentOrigin: json['document_origin'] as String?,
      level: json['level'] as String?,
      academicYear: json['academic_year'] as String?,
      isPublic: json['is_public'] as bool, // Supabase returns bool directly
      isDraft: json['is_draft'] as bool,   // Supabase returns bool directly
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      pdfPath: json['pdf_path'] as String?,
      previewHtml: json['preview_html'] as String? ?? '',
      isSynced: json['is_synced'] as bool? ?? false, // Assuming Supabase might not have these
      syncPending: json['sync_pending'] as bool? ?? false, // Assuming Supabase might not have these
      isOffline: false, // Not from Supabase, default to false
    );
  }

  // Method to convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'filiere': filiere,
      'subject': subject, // Include subject
      'document_type': documentType,
      'document_origin': documentOrigin,
      'level': level,
      'academic_year': academicYear,
      'is_public': isPublic,
      'is_draft': isDraft,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'pdf_path': pdfPath,
      'preview_html': previewHtml,
      // isSynced and syncPending are internal to local DB, not sent to Supabase
      // isOffline is also internal
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'filiere': filiere,
      'subject': subject, // Include subject
      'document_type': documentType,
      'document_origin': documentOrigin,
      'level': level,
      'academic_year': academicYear,
      'is_public': isPublic ? 1 : 0,
      'is_draft': isDraft ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'pdf_path': pdfPath,
      'preview_html': previewHtml,
      'is_synced': isSynced ? 1 : 0,
      'sync_pending': syncPending ? 1 : 0,
      'is_offline': isOffline ? 1 : 0, // ADDED
    };
  }

  factory DocumentModel.fromLocalMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      authorId: map['author_id'] as String,
      filiere: map['filiere'] as String,
      subject: map['subject'] as String, // Parse subject
      documentType: map['document_type'] as String?,
      documentOrigin: map['document_origin'] as String?,
      level: map['level'] as String?,
      academicYear: map['academic_year'] as String?,
      isPublic: (map['is_public'] == 1),
      isDraft: (map['is_draft'] == 1),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      pdfPath: map['pdf_path'] as String?,
      previewHtml: map['preview_html'] as String? ?? '',
      isSynced: (map['is_synced'] == 1),
      syncPending: (map['sync_pending'] == 1),
      isOffline: (map['is_offline'] == 1), // ADDED
    );
  }

  DocumentModel copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? filiere,
    String? subject, // Include subject in copyWith
    String? documentType,
    String? documentOrigin,
    String? level,
    String? academicYear,
    bool? isPublic,
    bool? isDraft,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? pdfPath,
    String? previewHtml,
    bool? isSynced,
    bool? syncPending,
    bool? isOffline, // ADDED
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      filiere: filiere ?? this.filiere,
      subject: subject ?? this.subject, // Use subject
      documentType: documentType ?? this.documentType,
      documentOrigin: documentOrigin ?? this.documentOrigin,
      level: level ?? this.level,
      academicYear: academicYear ?? this.academicYear,
      isPublic: isPublic ?? this.isPublic,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pdfPath: pdfPath ?? this.pdfPath,
      previewHtml: previewHtml ?? this.previewHtml,
      isSynced: isSynced ?? this.isSynced,
      syncPending: syncPending ?? this.syncPending,
      isOffline: isOffline ?? this.isOffline, // ADDED
    );
  }
}
