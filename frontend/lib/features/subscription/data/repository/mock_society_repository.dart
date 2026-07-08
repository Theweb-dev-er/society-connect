import 'dart:math';
import '../models/society.dart';

class MockSocietyRepository {
  static final List<Society> _societies = [
    Society(
      id: 'SOC001',
      name: 'Green Valley Apartments',
      code: 'GVA-7K9X2',
      address: '123 MG Road, Bangalore',
      totalFlats: 120,
      ownerId: 'R001',
      subscriptionId: 'SUB001',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      dualRolePolicy: DualRolePolicy.adminPlusOne,
    ),
  ];

  static final List<Subscription> _subscriptions = [
    Subscription(
      id: 'SUB001',
      societyId: 'SOC001',
      ownerId: 'R001',
      planId: 'growth',
      startDate: DateTime.now().subtract(const Duration(days: 90)),
      nextBilling: DateTime.now().add(const Duration(days: 1)),
      status: 'active',
      amount: 1499,
    ),
  ];

  static List<Society> getAllSocieties() => List.unmodifiable(_societies);

  static Society? findByCode(String code) {
    try {
      return _societies.firstWhere(
        (s) => s.code.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static Subscription? getSubscription(String societyId) {
    try {
      return _subscriptions.firstWhere((s) => s.societyId == societyId);
    } catch (_) {
      return null;
    }
  }

  /// Creates a new society + subscription. Returns the new Society.
  static Society createSociety({
    required String name,
    required String address,
    required int totalFlats,
    required String ownerId,
    required String planId,
    required double amount,
  }) {
    final societyId = 'SOC${_societies.length + 1}'.padLeft(6, '0');
    final subId = 'SUB${_subscriptions.length + 1}'.padLeft(6, '0');
    final code = _generateCode(name);

    final sub = Subscription(
      id: subId,
      societyId: societyId,
      ownerId: ownerId,
      planId: planId,
      startDate: DateTime.now(),
      nextBilling: DateTime.now().add(const Duration(days: 30)),
      status: 'active',
      amount: amount,
    );

    final society = Society(
      id: societyId,
      name: name,
      code: code,
      address: address,
      totalFlats: totalFlats,
      ownerId: ownerId,
      subscriptionId: subId,
      createdAt: DateTime.now(),
      dualRolePolicy: DualRolePolicy.adminPlusOne,
    );

    _subscriptions.add(sub);
    _societies.add(society);
    return society;
  }

  static String _generateCode(String name) {
    final prefix = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '')
        .split('')
        .take(3)
        .join();
    final base = prefix.isEmpty ? 'SOC' : prefix.padRight(3, 'X');
    final rand = Random();
    final suffix = List.generate(5, (_) {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      return chars[rand.nextInt(chars.length)];
    }).join();
    return '$base-$suffix';
  }

  // Dual role policy management
  static DualRolePolicy getDualRolePolicy(String societyId) {
    try {
      final society = _societies.firstWhere((s) => s.id == societyId);
      return society.dualRolePolicy;
    } catch (_) {
      return DualRolePolicy.adminPlusOne; // Default policy
    }
  }

  static void updateDualRolePolicy(String societyId, DualRolePolicy policy) {
    try {
      final index = _societies.indexWhere((s) => s.id == societyId);
      if (index != -1) {
        final oldSociety = _societies[index];
        _societies[index] = Society(
          id: oldSociety.id,
          name: oldSociety.name,
          code: oldSociety.code,
          address: oldSociety.address,
          totalFlats: oldSociety.totalFlats,
          ownerId: oldSociety.ownerId,
          subscriptionId: oldSociety.subscriptionId,
          createdAt: oldSociety.createdAt,
          dualRolePolicy: policy,
        );
      }
    } catch (_) {
      // Handle error silently for mock implementation
    }
  }

  static Society? getSocietyById(String societyId) {
    try {
      return _societies.firstWhere((s) => s.id == societyId);
    } catch (_) {
      return null;
    }
  }
}
