import 'package:flutter/material.dart';
import '../../../../core/api/visitor_service.dart';
import '../../../../features/auth/data/models/current_user.dart';

class VisitorNotificationDialog extends StatefulWidget {
  final Map<String, dynamic> visitor;
  final VoidCallback? onActionCompleted;

  const VisitorNotificationDialog({
    super.key,
    required this.visitor,
    this.onActionCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> visitor,
    VoidCallback? onActionCompleted,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => VisitorNotificationDialog(
        visitor: visitor,
        onActionCompleted: onActionCompleted,
      ),
    );
  }

  @override
  State<VisitorNotificationDialog> createState() => _VisitorNotificationDialogState();
}

class _VisitorNotificationDialogState extends State<VisitorNotificationDialog> {
  bool _isApproving = false;
  bool _isDenying = false;
  bool _isCollecting = false;

  String get _visitorId => widget.visitor['id']?.toString() ?? '';
  String get _visitorName => widget.visitor['name'] ?? 'Unknown Visitor';
  String get _visitorPhone => widget.visitor['phone'] ?? 'No phone provided';
  String get _visitorFlat => widget.visitor['flat'] ?? 'Flat';
  String get _visitorType => widget.visitor['type']?.toString().toUpperCase() ?? 'GUEST';

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t == 'delivery') {
      return Icons.local_shipping_outlined;
    } else if (t == 'service') {
      return Icons.build_outlined;
    }
    return Icons.person_outline;
  }

  Color _getColorForType(String type) {
    final t = type.toLowerCase();
    if (t == 'delivery') {
      return const Color(0xFFF97316); // Orange
    } else if (t == 'service') {
      return const Color(0xFF3B82F6); // Blue
    }
    return const Color(0xFF8B5CF6); // Purple
  }

  Future<void> _approveVisitor() async {
    if (_isApproving || _isDenying || _isCollecting) return;
    setState(() => _isApproving = true);

    try {
      await VisitorService().markEntered(_visitorId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_visitorName approved successfully.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (widget.onActionCompleted != null) {
          widget.onActionCompleted!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve entry: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _denyVisitor() async {
    if (_isApproving || _isDenying || _isCollecting) return;
    setState(() => _isDenying = true);

    // Mock denying visitor (pop and show status)
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entry denied for $_visitorName.'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.onActionCompleted != null) {
        widget.onActionCompleted!();
      }
    }
  }

  Future<void> _collectParcel() async {
    if (_isApproving || _isDenying || _isCollecting) return;
    setState(() => _isCollecting = true);

    try {
      // Mark as entered for parcel pick-up/drop-off
      await VisitorService().markEntered(_visitorId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Instructed to collect parcel at gate for $_visitorName.'),
            backgroundColor: const Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (widget.onActionCompleted != null) {
          widget.onActionCompleted!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request parcel collection: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCollecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getColorForType(_visitorType);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Visitor Notification',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Flat Number Title
                  Text(
                    _visitorFlat,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Society / Building Subtitle
                  Text(
                    CurrentUser.societyName ?? 'A Wing, Raj Empire Society',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Premium Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: typeColor.withOpacity(0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _getIconForType(_visitorType),
                        size: 44,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badge - e.g. DELIVERY-Swiggy
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _visitorType == 'DELIVERY'
                          ? 'DELIVERY-${_visitorName.toLowerCase().contains("swiggy") ? "Swiggy" : _visitorName.toLowerCase().contains("zomato") ? "Zomato" : "Courier"}'
                          : _visitorType,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Temperature & Mask Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusPill(
                        icon: Icons.thermostat_outlined,
                        color: Colors.orange,
                        label: '36.8 °C',
                      ),
                      const SizedBox(width: 12),
                      _buildStatusPill(
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF10B981),
                        label: 'Mask OK',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Visitor Detail Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Left Brand/Category Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _visitorType == 'DELIVERY'
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _visitorType == 'DELIVERY'
                                  ? Icons.shopping_bag_outlined
                                  : Icons.person_outline,
                              color: _visitorType == 'DELIVERY'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF3B82F6),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Visitor Name & Phone Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _visitorName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _visitorPhone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right Call Button
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Calling visitor $_visitorName ($_visitorPhone)...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Color(0xFF3B82F6),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bottom Action Buttons
                  // Approve Button (Full-width)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_isApproving || _isDenying || _isCollecting) ? null : _approveVisitor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isApproving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'APPROVE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Row: Deny and Collect Parcel
                  Row(
                    children: [
                      // Deny Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (_isApproving || _isDenying || _isCollecting) ? null : _denyVisitor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B7280),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isDenying
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.close, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'DENY',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Collect Parcel Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: (_isApproving || _isDenying || _isCollecting) ? null : _collectParcel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4B5563),
                              side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: _isCollecting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4B5563)),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'COLLECT PARCEL',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
