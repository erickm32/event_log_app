class Event {
  final int id;
  final String name;
  final int? categoryId;
  final String? observation;
  final DateTime? timestamp;
  final String status;
  final DateTime? processedAt;

  const Event({
    required this.id,
    required this.name,
    this.categoryId,
    this.observation,
    this.timestamp,
    required this.status,
    this.processedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as int,
        name: json['name'] as String,
        categoryId: json['category_id'] as int?,
        observation: json['observation'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
        status: json['status'] as String,
        processedAt: json['processed_at'] != null
            ? DateTime.parse(json['processed_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (categoryId != null) 'category_id': categoryId,
        if (observation != null) 'observation': observation,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };
}
