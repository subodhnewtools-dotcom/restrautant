class MessageTemplateModel {
  final String? id;
  final String title;
  final String body;
  final String? createdAt;

  MessageTemplateModel({
    this.id,
    required this.title,
    required this.body,
    this.createdAt,
  });

  factory MessageTemplateModel.fromMap(Map<String, dynamic> map) {
    return MessageTemplateModel(
      id: map['id'] as String?,
      title: map['title'] as String,
      body: map['body'] as String,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_at': createdAt,
    };
  }

  MessageTemplateModel copyWith({
    String? id,
    String? title,
    String? body,
    String? createdAt,
  }) {
    return MessageTemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
