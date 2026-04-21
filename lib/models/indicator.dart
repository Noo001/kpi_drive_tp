class Indicator {
  final String name;
  final int indicatorToMoId;

  Indicator({required this.name, required this.indicatorToMoId});

  factory Indicator.fromJson(Map<String, dynamic> json) {
    return Indicator(
      name: json['name'] ?? '',
      indicatorToMoId: json['indicator_to_mo_id'] ?? 0,
    );
  }
}
