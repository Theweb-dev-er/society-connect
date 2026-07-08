enum WorkflowStage { draft, pendingChecker, pendingApprover, approved, rejected }

enum OperationType { bill, expense }

class WorkflowItem {
  String id;
  OperationType type;
  String title;
  double amount;
  WorkflowStage stage;
  String submittedBy;
  DateTime submittedAt;
  List<AuditEvent> timeline;
  Map<String, dynamic> payload;
  String? rejectComment;

  WorkflowItem({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.stage,
    required this.submittedBy,
    required this.submittedAt,
    required this.timeline,
    required this.payload,
    this.rejectComment,
  });
}

class AuditEvent {
  final DateTime at;
  final String actor;
  final String actorRole;
  final String action;
  final String? comment;

  AuditEvent({
    required this.at,
    required this.actor,
    required this.actorRole,
    required this.action,
    this.comment,
  });
}

class BillPayload {
  String month;
  String year;
  List<BillEntry> entries;
  double totalAmount;
  int residentCount;

  BillPayload({
    required this.month,
    required this.year,
    required this.entries,
    required this.totalAmount,
    required this.residentCount,
  });

  Map<String, dynamic> toMap() => {
    'month': month,
    'year': year,
    'entries': entries.map((e) => e.toMap()).toList(),
    'totalAmount': totalAmount,
    'residentCount': residentCount,
  };

  static BillPayload fromMap(Map<String, dynamic> map) => BillPayload(
    month: map['month'] as String,
    year: map['year'] as String,
    entries: (map['entries'] as List).map((e) => BillEntry.fromMap(e)).toList(),
    totalAmount: (map['totalAmount'] as num).toDouble(),
    residentCount: map['residentCount'] as int,
  );
}

class BillEntry {
  String flat;
  String residentName;
  double amount;
  double? fine;

  BillEntry({
    required this.flat,
    required this.residentName,
    required this.amount,
    this.fine,
  });

  Map<String, dynamic> toMap() => {
    'flat': flat,
    'residentName': residentName,
    'amount': amount,
    if (fine != null) 'fine': fine,
  };

  static BillEntry fromMap(Map<String, dynamic> map) => BillEntry(
    flat: map['flat'] as String,
    residentName: map['residentName'] as String,
    amount: (map['amount'] as num).toDouble(),
    fine: map['fine'] != null ? (map['fine'] as num).toDouble() : null,
  );
}

class ExpensePayload {
  String category;
  String vendorName;
  String description;
  DateTime expenseDate;
  String? receiptUrl;

  ExpensePayload({
    required this.category,
    required this.vendorName,
    required this.description,
    required this.expenseDate,
    this.receiptUrl,
  });

  Map<String, dynamic> toMap() => {
    'category': category,
    'vendorName': vendorName,
    'description': description,
    'expenseDate': expenseDate.toIso8601String(),
    'receiptUrl': receiptUrl,
  };

  static ExpensePayload fromMap(Map<String, dynamic> map) => ExpensePayload(
    category: map['category'] as String,
    vendorName: map['vendorName'] as String,
    description: map['description'] as String,
    expenseDate: DateTime.parse(map['expenseDate'] as String),
    receiptUrl: map['receiptUrl'] as String?,
  );
}

class AuditLogEntry {
  final String id;
  final DateTime timestamp;
  final String actorName;
  final String actorRole;
  final String action;
  final String targetItem;
  final String targetId;
  final String? comment;

  AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.targetItem,
    required this.targetId,
    this.comment,
  });
}
