import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../state/role_provider.dart';
import 'home_discovery_screen.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _district = 'Colombo';
  bool _agreed = false;

  final _districts = const ['Colombo', 'Gampaha', 'Kandy', 'Galle', 'Kurunegala', 'Jaffna'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _createAccount() {
    pv.Provider.of<RoleProvider>(context, listen: false).setRole(AppRole.customer);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Create Customer Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Book trusted home services in a few taps',
                style: TextStyle(fontSize: 13.5, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              _Field(label: 'Full name', controller: _nameController, hint: 'Sanduni Perera'),
              const SizedBox(height: 14),
              _Field(
                label: 'Phone number',
                controller: _phoneController,
                hint: '77 123 4567',
                keyboardType: TextInputType.phone,
                prefixText: '+94 ',
              ),
              const SizedBox(height: 14),
              _Field(label: 'Home address', controller: _addressController, hint: 'No. 12, Lake Road'),
              const SizedBox(height: 14),
              Text('District', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outline.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _district,
                    isExpanded: true,
                    items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _district = v ?? _district),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: TextStyle(fontSize: 12.5, color: AppColors.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Create Account', onPressed: _agreed ? _createAccount : null),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Already have an account? Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? prefixText;
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: AppColors.surfaceLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outline.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }
}
