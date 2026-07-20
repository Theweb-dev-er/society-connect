class FamilyMember {
  final String id;
  final String name;
  final String phone;
  final String relationToPrimary;
  final bool isPrimary;

  FamilyMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationToPrimary,
    this.isPrimary = false,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      relationToPrimary: json['relation_to_primary'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relation_to_primary': relationToPrimary,
      'is_primary': isPrimary,
    };
  }
}
