class Vehicle {
  final String id;
  final String vehicleType;
  final String vehicleNumber;
  final String makeModel;

  Vehicle({
    required this.id,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.makeModel,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      vehicleType: json['vehicle_type'],
      vehicleNumber: json['vehicle_number'],
      makeModel: json['make_model'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'make_model': makeModel,
    };
  }
}
