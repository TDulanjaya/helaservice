import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../app_router.dart';
import 'nic_verification_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  bool _emergencyAvailable = true;

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
            'Are you sure you want to log out of your Service Provider account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              pv.Provider.of<RoleProvider>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showBankDetailsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bank & LankaQR Settlement',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Bank: Commercial Bank of Ceylon PLC',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('Branch: Kollupitiya Super Branch', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Account No: 8004 •••• •••• 1290', style: TextStyle(fontSize: 12)),
                    SizedBox(height: 4),
                    Text('LankaQR ID: LQR-HELA-88219',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;

    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : 'Sunil Bandara';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : 'provider.sample@gmail.com';
    final phone = user?.phone?.isNotEmpty == true ? user!.phone! : '71 456 7890';
    final category = user?.serviceCategory ?? 'Master Electrician & AC Specialist';
    final district = user?.district ?? 'Colombo & Gampaha';
    final nic = user?.nic?.isNotEmpty == true ? user!.nic! : '198812345678';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Artisan Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch role',
            onPressed: () => showRoleSwitchSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFF00685F).withValues(alpha: 0.15),
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'P',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const _StatColumn(label: 'Rating', value: '4.9 ★', sub: '142 reviews'),
                        Container(width: 1, height: 28, color: AppColors.outline.withValues(alpha: 0.2)),
                        const _StatColumn(label: 'Jobs Done', value: '142', sub: 'Island-wide'),
                        Container(width: 1, height: 28, color: AppColors.outline.withValues(alpha: 0.2)),
                        const _StatColumn(label: 'On-Time', value: '99.2%', sub: 'Prompt Arrival'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user,
                              size: 18, color: Color(0xFF008378)),
                          SizedBox(width: 6),
                          Text(
                            'Government & Police Verified',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF008378),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NicVerificationScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'View Docs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('NIC: $nic • NVQ Level 4 Certified Specialist',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Operating District: $district • Phone: +94 $phone',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEA619).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFFEA619).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEA619).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Color(0xFF9E6500), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Withdrawable Balance',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF684000),
                          ),
                        ),
                        Text(
                          'LKR 9,500.00',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _showBankDetailsSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF684000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Cashout',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            const Text(
              'Job Dispatch Settings',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _emergencyAvailable,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Emergency Night Callout',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Accept urgent visits between 8 PM - 6 AM at 1.5x surge rate',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.onSurfaceVariant),
                    ),
                    onChanged: (val) =>
                        setState(() => _emergencyAvailable = val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.account_balance,
                        color: AppColors.primary, size: 20),
                    title: const Text('Settlement Account & LankaQR',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Commercial Bank • Ending in 1290',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: _showBankDetailsSheet,
                  ),

                ],
              ),
            ),

            const SizedBox(height: 14),
            InkWell(
              onTap: () => showRoleSwitchSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_repair_service_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch to Customer Mode',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Book technicians for your own home or office',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.outline),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
        Text(
          sub,
          style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
