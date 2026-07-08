import '../models/workflow_models.dart';

class MockWorkflowRepository {
  static final List<WorkflowItem> _items = [
    // Bill 1 - Pending Checker
    WorkflowItem(
      id: 'BILL-001',
      type: OperationType.bill,
      title: 'July 2026 - Society Maintenance Bills',
      amount: 315000,
      stage: WorkflowStage.pendingChecker,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime(2026, 6, 28, 10, 30),
      rejectComment: null,
      timeline: [
        AuditEvent(
          at: DateTime(2026, 6, 28, 10, 30),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: 'Submitted for review',
          comment: 'July bills ready for verification',
        ),
      ],
      payload: BillPayload(
        month: 'July',
        year: '2026',
        totalAmount: 315000,
        residentCount: 90,
        entries: [
          BillEntry(flat: 'A-101', residentName: 'Aman Gupta', amount: 3500),
          BillEntry(flat: 'A-102', residentName: 'Priya Sharma', amount: 3500),
          BillEntry(flat: 'A-103', residentName: 'Rohan Mehta', amount: 3500),
        ],
      ).toMap(),
    ),
    // Bill 2 - Pending Approver
    WorkflowItem(
      id: 'BILL-002',
      type: OperationType.bill,
      title: 'June 2026 - Society Maintenance Bills',
      amount: 315000,
      stage: WorkflowStage.pendingApprover,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime(2026, 5, 30, 14, 15),
      rejectComment: null,
      timeline: [
        AuditEvent(
          at: DateTime(2026, 5, 30, 14, 15),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: 'Submitted for review',
        ),
        AuditEvent(
          at: DateTime(2026, 5, 31, 9, 0),
          actor: 'Sunita Patel',
          actorRole: 'Treasurer',
          action: 'Checked and forwarded',
          comment: 'Amounts verified against ledger',
        ),
      ],
      payload: BillPayload(
        month: 'June',
        year: '2026',
        totalAmount: 315000,
        residentCount: 90,
        entries: [
          BillEntry(flat: 'A-101', residentName: 'Aman Gupta', amount: 3500),
          BillEntry(flat: 'A-102', residentName: 'Priya Sharma', amount: 3500),
        ],
      ).toMap(),
    ),
    // Bill 3 - Approved
    WorkflowItem(
      id: 'BILL-003',
      type: OperationType.bill,
      title: 'May 2026 - Society Maintenance Bills',
      amount: 315000,
      stage: WorkflowStage.approved,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime(2026, 4, 28, 11, 0),
      rejectComment: null,
      timeline: [
        AuditEvent(
          at: DateTime(2026, 4, 28, 11, 0),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: 'Submitted for review',
        ),
        AuditEvent(
          at: DateTime(2026, 4, 29, 10, 30),
          actor: 'Sunita Patel',
          actorRole: 'Treasurer',
          action: 'Checked and forwarded',
        ),
        AuditEvent(
          at: DateTime(2026, 4, 30, 16, 0),
          actor: 'Vikram Rao',
          actorRole: 'President',
          action: 'Approved',
          comment: 'All residents notified',
        ),
      ],
      payload: BillPayload(
        month: 'May',
        year: '2026',
        totalAmount: 315000,
        residentCount: 90,
        entries: [
          BillEntry(flat: 'A-101', residentName: 'Aman Gupta', amount: 3500),
          BillEntry(flat: 'B-201', residentName: 'Neha Gupta', amount: 3500),
        ],
      ).toMap(),
    ),
    // Bill 4 - Rejected (back to maker)
    WorkflowItem(
      id: 'BILL-004',
      type: OperationType.bill,
      title: 'April 2026 - Society Maintenance Bills',
      amount: 283500,
      stage: WorkflowStage.rejected,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime(2026, 3, 28, 9, 0),
      rejectComment: 'Fine amounts not updated for 5 overdue flats. Please recalculate and resubmit.',
      timeline: [
        AuditEvent(
          at: DateTime(2026, 3, 28, 9, 0),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: 'Submitted for review',
        ),
        AuditEvent(
          at: DateTime(2026, 3, 29, 11, 15),
          actor: 'Sunita Patel',
          actorRole: 'Treasurer',
          action: 'Rejected',
          comment: 'Fine amounts not updated for 5 overdue flats. Please recalculate and resubmit.',
        ),
      ],
      payload: BillPayload(
        month: 'April',
        year: '2026',
        totalAmount: 283500,
        residentCount: 90,
        entries: [
          BillEntry(flat: 'A-101', residentName: 'Aman Gupta', amount: 3500),
        ],
      ).toMap(),
    ),
    // Expense 1 - Pending Checker
    WorkflowItem(
      id: 'EXP-001',
      type: OperationType.expense,
      title: 'Elevator AMC - Q2 2026',
      amount: 45000,
      stage: WorkflowStage.pendingChecker,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime(2026, 6, 27, 16, 45),
      rejectComment: null,
      timeline: [
        AuditEvent(
          at: DateTime(2026, 6, 27, 16, 45),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: 'Submitted for review',
        ),
      ],
      payload: ExpensePayload(
        category: 'Repairs & Maintenance',
        vendorName: 'Kone Elevators Pvt. Ltd.',
        description: 'Annual Maintenance Contract for Building A & B elevators. Quarterly payment.',
        expenseDate: DateTime(2026, 6, 27),
        receiptUrl: 'receipt_kone_q2.pdf',
      ).toMap(),
    ),
    // Expense 2 - Pending Approver
    WorkflowItem(
      id: 'EXP-002',
      type: OperationType.expense,
      title: 'Security Agency Monthly Payment',
      amount: 72000,
      stage: WorkflowStage.pendingApprover,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime(2026, 6, 25, 11, 0),
      rejectComment: null,
      timeline: [
        AuditEvent(
          at: DateTime(2026, 6, 25, 11, 0),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: 'Submitted for review',
        ),
        AuditEvent(
          at: DateTime(2026, 6, 26, 10, 0),
          actor: 'Sunita Patel',
          actorRole: 'Treasurer',
          action: 'Checked and forwarded',
          comment: 'Invoice matches contract terms',
        ),
      ],
      payload: ExpensePayload(
        category: 'Salaries & Services',
        vendorName: 'Vanguard Security Services',
        description: 'Monthly security guard deployment (6 guards) - June 2026',
        expenseDate: DateTime(2026, 6, 25),
        receiptUrl: 'invoice_vanguard_jun.pdf',
      ).toMap(),
    ),
    // Expense 3 - Approved
    WorkflowItem(
      id: 'EXP-003',
      type: OperationType.expense,
      title: 'Society Common Area Painting',
      amount: 125000,
      stage: WorkflowStage.approved,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime(2026, 5, 15, 14, 30),
      rejectComment: null,
      timeline: [
        AuditEvent(
          at: DateTime(2026, 5, 15, 14, 30),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: 'Submitted for review',
        ),
        AuditEvent(
          at: DateTime(2026, 5, 16, 9, 30),
          actor: 'Sunita Patel',
          actorRole: 'Treasurer',
          action: 'Checked and forwarded',
        ),
        AuditEvent(
          at: DateTime(2026, 5, 17, 11, 0),
          actor: 'Vikram Rao',
          actorRole: 'President',
          action: 'Approved',
          comment: 'Approved after AGM resolution.',
        ),
      ],
      payload: ExpensePayload(
        category: 'Repairs & Maintenance',
        vendorName: 'ColorCraft Interiors',
        description: 'Complete painting of lobby, corridors and clubhouse',
        expenseDate: DateTime(2026, 5, 15),
        receiptUrl: 'invoice_colorcraft.pdf',
      ).toMap(),
    ),
    // Expense 4 - Draft
    WorkflowItem(
      id: 'EXP-004',
      type: OperationType.expense,
      title: 'Water Tank Cleaning',
      amount: 8500,
      stage: WorkflowStage.draft,
      submittedBy: 'Rajesh Sharma (Secretary)',
      submittedAt: DateTime(2026, 6, 29, 9, 0),
      rejectComment: null,
      timeline: [
        AuditEvent(
          at: DateTime(2026, 6, 29, 9, 0),
          actor: 'Rajesh Sharma',
          actorRole: 'Secretary',
          action: 'Saved as draft',
        ),
      ],
      payload: ExpensePayload(
        category: 'Utilities',
        vendorName: 'AquaClean Services',
        description: 'Underground and overhead water tank cleaning - 4 tanks',
        expenseDate: DateTime(2026, 6, 29),
        receiptUrl: null,
      ).toMap(),
    ),
  ];

  // Audit log entries
  static final List<AuditLogEntry> _auditLog = [
    AuditLogEntry(id: 'A1', timestamp: DateTime(2026, 6, 28, 10, 30), actorName: 'Rajesh Sharma', actorRole: 'Secretary', action: 'Submitted', targetItem: 'July 2026 Bills', targetId: 'BILL-001'),
    AuditLogEntry(id: 'A2', timestamp: DateTime(2026, 6, 27, 16, 45), actorName: 'Rajesh Sharma', actorRole: 'Secretary', action: 'Submitted', targetItem: 'Elevator AMC Q2', targetId: 'EXP-001'),
    AuditLogEntry(id: 'A3', timestamp: DateTime(2026, 6, 26, 10, 0), actorName: 'Sunita Patel', actorRole: 'Treasurer', action: 'Checked & Forwarded', targetItem: 'Security Agency Payment', targetId: 'EXP-002', comment: 'Invoice matches contract'),
    AuditLogEntry(id: 'A4', timestamp: DateTime(2026, 6, 25, 11, 0), actorName: 'Rajesh Sharma', actorRole: 'Secretary', action: 'Submitted', targetItem: 'Security Agency Payment', targetId: 'EXP-002'),
    AuditLogEntry(id: 'A5', timestamp: DateTime(2026, 5, 31, 9, 0), actorName: 'Sunita Patel', actorRole: 'Treasurer', action: 'Checked & Forwarded', targetItem: 'June 2026 Bills', targetId: 'BILL-002', comment: 'Amounts verified against ledger'),
    AuditLogEntry(id: 'A6', timestamp: DateTime(2026, 5, 30, 14, 15), actorName: 'Rajesh Sharma', actorRole: 'Secretary', action: 'Submitted', targetItem: 'June 2026 Bills', targetId: 'BILL-002'),
    AuditLogEntry(id: 'A7', timestamp: DateTime(2026, 5, 17, 11, 0), actorName: 'Vikram Rao', actorRole: 'President', action: 'Approved', targetItem: 'Common Area Painting', targetId: 'EXP-003', comment: 'Approved after AGM resolution'),
    AuditLogEntry(id: 'A8', timestamp: DateTime(2026, 5, 16, 9, 30), actorName: 'Sunita Patel', actorRole: 'Treasurer', action: 'Checked & Forwarded', targetItem: 'Common Area Painting', targetId: 'EXP-003'),
    AuditLogEntry(id: 'A9', timestamp: DateTime(2026, 5, 15, 14, 30), actorName: 'Rajesh Sharma', actorRole: 'Secretary', action: 'Submitted', targetItem: 'Common Area Painting', targetId: 'EXP-003'),
    AuditLogEntry(id: 'A10', timestamp: DateTime(2026, 4, 30, 16, 0), actorName: 'Vikram Rao', actorRole: 'President', action: 'Approved', targetItem: 'May 2026 Bills', targetId: 'BILL-003'),
    AuditLogEntry(id: 'A11', timestamp: DateTime(2026, 4, 29, 10, 30), actorName: 'Sunita Patel', actorRole: 'Treasurer', action: 'Checked & Forwarded', targetItem: 'May 2026 Bills', targetId: 'BILL-003'),
    AuditLogEntry(id: 'A12', timestamp: DateTime(2026, 4, 28, 11, 0), actorName: 'Rajesh Sharma', actorRole: 'Secretary', action: 'Submitted', targetItem: 'May 2026 Bills', targetId: 'BILL-003'),
    AuditLogEntry(id: 'A13', timestamp: DateTime(2026, 3, 29, 11, 15), actorName: 'Sunita Patel', actorRole: 'Treasurer', action: 'Rejected', targetItem: 'April 2026 Bills', targetId: 'BILL-004', comment: 'Fine amounts not updated for 5 overdue flats'),
    AuditLogEntry(id: 'A14', timestamp: DateTime(2026, 3, 28, 9, 0), actorName: 'Rajesh Sharma', actorRole: 'Secretary', action: 'Submitted', targetItem: 'April 2026 Bills', targetId: 'BILL-004'),
  ];

  static List<WorkflowItem> getAll() => _items;
  static List<WorkflowItem> getBills() => _items.where((i) => i.type == OperationType.bill).toList();
  static List<WorkflowItem> getExpenses() => _items.where((i) => i.type == OperationType.expense).toList();
  static List<WorkflowItem> getByStage(WorkflowStage stage) => _items.where((i) => i.stage == stage).toList();

  static List<WorkflowItem> getPendingChecker() =>
      _items.where((i) => i.stage == WorkflowStage.pendingChecker).toList();

  static List<WorkflowItem> getPendingApprover() =>
      _items.where((i) => i.stage == WorkflowStage.pendingApprover).toList();

  static List<AuditLogEntry> getAuditLog() => _auditLog;

  static WorkflowItem? getById(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  static void updateStage(String id, WorkflowStage newStage, {String? actor, String? actorRole, String? action, String? comment}) {
    final item = getById(id);
    if (item == null) return;
    item.stage = newStage;
    item.timeline.add(AuditEvent(
      at: DateTime.now(),
      actor: actor ?? 'Unknown',
      actorRole: actorRole ?? 'Unknown',
      action: action ?? 'Stage updated',
      comment: comment,
    ));
    _auditLog.add(AuditLogEntry(
      id: 'A${_auditLog.length + 1}',
      timestamp: DateTime.now(),
      actorName: actor ?? 'Unknown',
      actorRole: actorRole ?? 'Unknown',
      action: action ?? 'Updated',
      targetItem: item.title,
      targetId: item.id,
      comment: comment,
    ));
    if (newStage == WorkflowStage.rejected && comment != null) {
      item.rejectComment = comment;
    }
  }

  static void addItem(WorkflowItem item) {
    _items.add(item);
    _auditLog.add(AuditLogEntry(
      id: 'A${_auditLog.length + 1}',
      timestamp: item.submittedAt,
      actorName: item.submittedBy,
      actorRole: 'Secretary',
      action: item.stage == WorkflowStage.draft ? 'Saved as draft' : 'Submitted',
      targetItem: item.title,
      targetId: item.id,
    ));
  }
}
