class LikeModel {
  final String id;
  final String userId;
  final String targetId;
  final String targetType; // 'publication' or 'important_info'

  LikeModel({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'],
      userId: json['user_id'],
      targetId: json['target_id'],
      targetType: json['target_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'target_id': targetId,
      'target_type': targetType,
    };
  }
}
