class PhotoMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String imagePath;
  final DateTime timestamp;
  final String? description;
  final String? comment;

  PhotoMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.timestamp,
    this.description,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'description': description,
      'comment': comment,
    };
  }

  factory PhotoMarker.fromJson(Map<String, dynamic> json) {
    return PhotoMarker(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imagePath: json['imagePath'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      description: json['description'],
      comment: json['comment'],
    );
  }

  PhotoMarker copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? imagePath,
    DateTime? timestamp,
    String? description,
    String? comment,
  }) {
    return PhotoMarker(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      comment: comment ?? this.comment,
    );
  }
}