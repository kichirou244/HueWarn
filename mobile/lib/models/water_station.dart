class WaterStation {
  final String id;
  final String name;
  final String area;
  final double depth;
  final double? change10m;
  final double? change1h;
  final double? change6h;
  final bool isTarget;
  final int alertLevel;

  const WaterStation({
    required this.id,
    required this.name,
    required this.area,
    required this.depth,
    this.change10m,
    this.change1h,
    this.change6h,
    required this.isTarget,
    required this.alertLevel,
  });

  factory WaterStation.fromJson(Map<String, dynamic> json) {
    return WaterStation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      area: json['area'] as String? ?? '',
      depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
      change10m: (json['change10m'] as num?)?.toDouble(),
      change1h: (json['change1h'] as num?)?.toDouble(),
      change6h: (json['change6h'] as num?)?.toDouble(),
      isTarget: json['isTarget'] as bool? ?? false,
      alertLevel: json['alertLevel'] as int? ?? 0,
    );
  }
}

class WaterLevelHistoryPoint {
  final String timePoint;
  final double depth;

  const WaterLevelHistoryPoint({
    required this.timePoint,
    required this.depth,
  });

  factory WaterLevelHistoryPoint.fromJson(Map<String, dynamic> json) {
    return WaterLevelHistoryPoint(
      timePoint: json['timePoint'] as String? ?? '',
      depth: (json['depth'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WaterLevelSummary {
  final String updatedAt;
  final int highestAlertLevel;
  final bool rapidIncreaseDetected;
  final double maxDepth;
  final List<WaterStation> stations;
  final Map<String, List<WaterLevelHistoryPoint>> history;

  const WaterLevelSummary({
    required this.updatedAt,
    required this.highestAlertLevel,
    required this.rapidIncreaseDetected,
    required this.maxDepth,
    required this.stations,
    required this.history,
  });

  factory WaterLevelSummary.fromJson(Map<String, dynamic> json) {
    final stationsList = (json['stations'] as List<dynamic>?)
            ?.map((e) => WaterStation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final historyMap = <String, List<WaterLevelHistoryPoint>>{};
    if (json['history'] is Map<String, dynamic>) {
      (json['history'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          historyMap[key] = value
              .map((e) => WaterLevelHistoryPoint.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      });
    }

    return WaterLevelSummary(
      updatedAt: json['updatedAt'] as String? ?? '',
      highestAlertLevel: json['highestAlertLevel'] as int? ?? 0,
      rapidIncreaseDetected: json['rapidIncreaseDetected'] as bool? ?? false,
      maxDepth: (json['maxDepth'] as num?)?.toDouble() ?? 0.0,
      stations: stationsList,
      history: historyMap,
    );
  }
}
