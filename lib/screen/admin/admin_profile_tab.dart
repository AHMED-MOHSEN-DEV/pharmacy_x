import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_x/widgets/responsive_field.dart';

// ← لا يوجد Scaffold هنا
class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  String _name = '';
  String _email = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        _name = doc.data()?['name'] ?? user.displayName ?? 'Admin';
        _email = doc.data()?['email'] ?? user.email ?? '';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Align(
      alignment: isDesktop ? Alignment.topCenter : Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 520 : double.infinity,
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 24 : 16,
            isDesktop ? 24 : 24,
            isDesktop ? 24 : 16,
            110,
          ),
          children: [
            // Avatar + name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: isDesktop ? 36 : 44,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.12),
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontSize: isDesktop ? 28 : 34,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 10 : 14),
                  Text(
                    _name,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isDesktop ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isDesktop ? 24 : 28),

            _ProfileTile(
              label: 'Role',
              value: 'Administrator',
              icon: Icons.shield_outlined,
              isDesktop: isDesktop,
            ),
            SizedBox(height: isDesktop ? 8 : 10),
            _ProfileTile(
              label: 'Email',
              value: _email,
              icon: Icons.email_outlined,
              isDesktop: isDesktop,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDesktop;

  const _ProfileTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: isDesktop ? 18 : 20),
          SizedBox(width: isDesktop ? 12 : 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isDesktop ? 12 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isDesktop ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }
}