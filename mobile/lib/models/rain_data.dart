class RainStation {
  final String stationId;
  final String stationName;
  final String area;
  final double sumDepth;
  final String level;
  final double difference;

  const RainStation({
    required this.stationId,
    required this.stationName,
    required this.area,
    required this.sumDepth,
    required this.level,
    required this.difference,
  });

  factory RainStation.fromJson(Map<String, dynamic> json) {
    return RainStation(
      stationId: json['stationId'] as String? ?? '',
      stationName: json['stationName'] as String? ?? '',
      area: json['area'] as String? ?? '',
      sumDepth: (json['sumDepth'] as num?)?.toDouble() ?? 0.0,
      level: json['level'] as String? ?? '',
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RainSummary {
  final String updatedAt;
  final int cityId;
  final List<RainStation> stations;
  final bool hasSignificantChanges;
  final String summaryText;

  const RainSummary({
    required this.updatedAt,
    required this.cityId,
    required this.stations,
    required this.hasSignificantChanges,
    required this.summaryText,
  });

  factory RainSummary.fromJson(Map<String, dynamic> json) {
    final stationsList = (json['stations'] as List<dynamic>?)
            ?.map((e) => RainStation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return RainSummary(
      updatedAt: json['updatedAt'] as String? ?? '',
      cityId: json['cityId'] as int? ?? 31,
      stations: stationsList,
      hasSignificantChanges: json['hasSignificantChanges'] as bool? ?? false,
      summaryText: json['summaryText'] as String? ?? '',
    );
  }
}
