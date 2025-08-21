class SearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String type;
  final String? icon;
  final Map<String, dynamic> address;

  SearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.icon,
    required this.address,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      displayName: json['display_name'] ?? '',
      latitude: double.tryParse(json['lat'] ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['lon'] ?? '0.0') ?? 0.0,
      type: json['type'] ?? 'unknown',
      icon: json['icon'],
      address: json['address'] ?? {},
    );
  }

  String get shortName {
    if (address['name'] != null && address['name'].toString().isNotEmpty) {
      return address['name'];
    }
    if (address['amenity'] != null) {
      return address['amenity'];
    }
    if (address['shop'] != null) {
      return address['shop'];
    }
    if (address['tourism'] != null) {
      return address['tourism'];
    }
    if (address['building'] != null) {
      return address['building'];
    }
    
    List<String> parts = displayName.split(',');
    return parts.first.trim();
  }

  String get subtitle {
    List<String> parts = [];
    
    if (address['city'] != null) {
      parts.add(address['city']);
    } else if (address['town'] != null) {
      parts.add(address['town']);
    } else if (address['village'] != null) {
      parts.add(address['village']);
    }
    
    if (address['country'] != null) {
      parts.add(address['country']);
    }
    
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'SearchResult(displayName: $displayName, lat: $latitude, lon: $longitude)';
  }
}