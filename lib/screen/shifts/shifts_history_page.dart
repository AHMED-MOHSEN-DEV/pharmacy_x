import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/responsive_field.dart';

class ShiftsHistoryPage extends StatefulWidget {
  const ShiftsHistoryPage({super.key});

  @override
  State<ShiftsHistoryPage> createState() => _ShiftsHistoryPageState();
}

class _ShiftsHistoryPageState extends State<ShiftsHistoryPage> {
  String _searchQuery = '';
  String _filterType = 'All';

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shifts History',
          style: TextStyle(fontSize: isDesktop ? 15 : 18),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: isDesktop ? 10 : 12,
            ),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: TextStyle(fontSize: isDesktop ? 13 : 15),
                  decoration: InputDecoration(
                    isDense: isDesktop,
                    hintText: 'Search by name or shift number...',
                    hintStyle: TextStyle(fontSize: isDesktop ? 12 : 14),
                    prefixIcon: Icon(
                      Icons.search,
                      size: isDesktop ? 18 : 22,
                    ),
                    contentPadding: ResponsiveLayout.fieldPadding(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isDesktop ? 10 : 14),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: isDesktop ? 8 : 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Surplus', 'Deficit', 'Balanced']
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: isDesktop ? 11 : 13,
                                ),
                              ),
                              selected: _filterType == filter,
                              onSelected: (_) => setState(() => _filterType = filter),
                              visualDensity: isDesktop
                                  ? VisualDensity.compact
                                  : VisualDensity.standard,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shifts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: isDesktop ? 42 : 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No shifts recorded yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: isDesktop ? 13 : 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final diff = (data['difference'] as num?)?.toDouble() ?? 0;
                  final name = (data['employeeName'] ?? '').toString().toLowerCase();
                  final shift = (data['shiftNumber'] ?? '').toString().toLowerCase();

                  if (_searchQuery.isNotEmpty) {
                    if (!name.contains(_searchQuery) && !shift.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  if (_filterType == 'Surplus' && diff <= 0) return false;
                  if (_filterType == 'Deficit' && diff >= 0) return false;
                  if (_filterType == 'Balanced' && diff != 0) return false;

                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No results for current filter',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isDesktop ? 12 : 15,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: isDesktop ? 12 : 14,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 8 : 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _ShiftCard(docId: doc.id,data: data, isDesktop: isDesktop);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDesktop;
  final String docId;


  const _ShiftCard({
  required this.docId,
  required this.data,
  required this.isDesktop,
});

  @override
  Widget build(BuildContext context) {
    final diff = (data['difference'] as num?)?.toDouble() ?? 0;
    final system = (data['systemAmount'] as num?)?.toDouble() ?? 0;
    final actual = (data['actualAmount'] as num?)?.toDouble() ?? 0;
    final name = (data['employeeName'] ?? 'Unknown').toString();
    final shiftNum = (data['shiftNumber'] ?? '-').toString();
    final date = (data['date'] ?? '-').toString();
    final time = (data['time'] ?? '-').toString();

    final isPositive = diff > 0;
    final isZero = diff == 0;

    final diffColor = isZero
        ? Colors.grey.shade500
        : isPositive
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 8 : 10,
                  vertical: isDesktop ? 4 : 5,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shiftNum,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isDesktop ? 12 : 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.person_outline,
                size: isDesktop ? 14 : 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 14,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
             Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      '$date $time',
      style: TextStyle(
        fontSize: isDesktop ? 11 : 12,
        color: Colors.grey.shade500,
      ),
    ),
    SizedBox(width: 8),

    /// 🔴 زر الحذف
    InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Shift"),
            content: Text("Are you sure you want to delete this shift?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete"),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseFirestore.instance
              .collection('shifts')
              .doc(docId)
              .delete();
        }
      },
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Colors.red,
          size: isDesktop ? 16 : 20,
        ),
      ),
    ),
  ],
)
            ],
          ),
          SizedBox(height: isDesktop ? 10 : 12),
          const Divider(height: 1),
          SizedBox(height: isDesktop ? 10 : 12),
          Row(
            children: [
              Expanded(
                child: _AmountCell(
                  label: 'System',
                  value: system,
                  isDesktop: isDesktop,
                  color: Colors.blueGrey,
                ),
              ),
              SizedBox(width: isDesktop ? 8 : 10),
              Expanded(
                child: _AmountCell(
                  label: 'Actual',
                  value: actual,
                  isDesktop: isDesktop,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(width: isDesktop ? 8 : 10),
              Expanded(
                child: _AmountCell(
                  label: 'Difference',
                  value: diff,
                  isDesktop: isDesktop,
                  color: diffColor,
                  showSign: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDesktop;
  final bool showSign;

  const _AmountCell({
    required this.label,
    required this.value,
    required this.color,
    required this.isDesktop,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final sign = showSign && value > 0 ? '+' : '';

    return Container(
      padding: EdgeInsets.all(isDesktop ? 8 : 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isDesktop ? 10 : 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isDesktop ? 2 : 4),
          Text(
            '$sign${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isDesktop ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'EGP',
            style: TextStyle(
              fontSize: isDesktop ? 9 : 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}