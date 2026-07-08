enum DualRolePolicy {
  adminPlusOne, // Admin can hold exactly one workflow role
  separateAdmin, // Admin cannot hold any workflow roles
}

class Society {
  final String id;
  final String name;
  final String code; // Shareable invite code (e.g., GVA-7K9X2)
  final String address;
  final int totalFlats;
  final String ownerId;
  final String? subscriptionId;
  final DateTime createdAt;
  final DualRolePolicy dualRolePolicy;

  Society({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.totalFlats,
    required this.ownerId,
    this.subscriptionId,
    required this.createdAt,
    this.dualRolePolicy = DualRolePolicy.adminPlusOne,
  });
}

class SubscriptionPlan {
  final String id;
  final String name;
  final int maxFlats;
  final double monthlyPrice;
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.maxFlats,
    required this.monthlyPrice,
    required this.features,
    this.isPopular = false,
  });

  static const List<SubscriptionPlan> all = [
    SubscriptionPlan(
      id: 'starter',
      name: 'Starter',
      maxFlats: 50,
      monthlyPrice: 499,
      features: [
        'Up to 50 flats',
        '1 Admin account',
        'Bill generation & payment',
        'Complaints & notices',
        'Visitor management',
      ],
    ),
    SubscriptionPlan(
      id: 'growth',
      name: 'Growth',
      maxFlats: 150,
      monthlyPrice: 1499,
      isPopular: true,
      features: [
        'Up to 150 flats',
        'Multiple admin accounts',
        'Maker-Checker-Approver workflow',
        'Audit logs',
        'Priority email support',
      ],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Premium',
      maxFlats: 500,
      monthlyPrice: 3999,
      features: [
        'Up to 500 flats',
        'Custom branding',
        'Advanced reports',
        'Priority phone support',
        '24/7 emergency line',
      ],
    ),
  ];
}

class Subscription {
  final String id;
  final String societyId;
  final String ownerId;
  final String planId;
  final DateTime startDate;
  final DateTime nextBilling;
  final String status; // active | trial | expired | cancelled
  final double amount;

  Subscription({
    required this.id,
    required this.societyId,
    required this.ownerId,
    required this.planId,
    required this.startDate,
    required this.nextBilling,
    required this.status,
    required this.amount,
  });
}
