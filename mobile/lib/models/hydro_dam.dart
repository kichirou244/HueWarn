class HydroTimelinePoint {
  final String hour;
  final String date;
  final String timePoint;
  final double waterLevel;
  final double inFlow;
  final double outFlow;

  const HydroTimelinePoint({
    required this.hour,
    required this.date,
    required this.timePoint,
    required this.waterLevel,
    required this.inFlow,
    required this.outFlow,
  });

  factory HydroTimelinePoint.fromJson(Map<String, dynamic> json) {
    return HydroTimelinePoint(
      hour: json['hour'] as String? ?? '',
      date: json['date'] as String? ?? '',
      timePoint: json['timePoint'] as String? ?? '',
      waterLevel: (json['waterLevel'] as num?)?.toDouble() ?? 0.0,
      inFlow: (json['inFlow'] as num?)?.toDouble() ?? 0.0,
      outFlow: (json['outFlow'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HydroDam {
  final int id;
  final int loaicongtrinh;
  final int tencongtrinh;
  final String name;
  final String river;
  final double waterLevel;
  final double inFlow;
  final double outFlow;
  final double outFlowChange;
  final String recordedAt;
  final String updatedAt;
  final List<HydroTimelinePoint> timeline;

  const HydroDam({
    required this.id,
    required this.loaicongtrinh,
    required this.tencongtrinh,
    required this.name,
    required this.river,
    required this.waterLevel,
    required this.inFlow,
    required this.outFlow,
    required this.outFlowChange,
    required this.recordedAt,
    required this.updatedAt,
    this.timeline = const [],
  });

  factory HydroDam.fromJson(Map<String, dynamic> json) {
    final damName = json['name'] as String? ?? '';
    final defaultRiver = damName.contains('Hương Điền') ? 'Sông Bồ' : 'Sông Hương';

    final timelineList = (json['timeline'] as List<dynamic>?)
            ?.map((e) => HydroTimelinePoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return HydroDam(
      id: json['id'] as int? ?? 0,
      loaicongtrinh: json['loaicongtrinh'] as int? ?? 0,
      tencongtrinh: json['tencongtrinh'] as int? ?? 0,
      name: damName,
      river: json['river'] as String? ?? defaultRiver,
      waterLevel: (json['waterLevel'] as num?)?.toDouble() ?? 0.0,
      inFlow: (json['inFlow'] as num?)?.toDouble() ?? 0.0,
      outFlow: (json['outFlow'] as num?)?.toDouble() ?? 0.0,
      outFlowChange: (json['outFlowChange'] as num?)?.toDouble() ?? 0.0,
      recordedAt: json['recordedAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      timeline: timelineList,
    );
  }
}

class HydroSummary {
  final String updatedAt;
  final String queryDate;
  final List<HydroDam> dams;

  const HydroSummary({
    required this.updatedAt,
    required this.queryDate,
    required this.dams,
  });

  factory HydroSummary.fromJson(Map<String, dynamic> json) {
    final damsList = (json['dams'] as List<dynamic>?)
            ?.map((e) => HydroDam.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return HydroSummary(
      updatedAt: json['updatedAt'] as String? ?? '',
      queryDate: json['queryDate'] as String? ?? '',
      dams: damsList,
    );
  }
}
