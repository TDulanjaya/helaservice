import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../state/role_provider.dart';
import '../../../models/user_profile.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/nic_verification_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserProfile? initialProfile;

  const CompleteProfileScreen({super.key, this.initialProfile});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  AppRole _selectedRole = AppRole.customer;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nicController = TextEditingController();

  String _district = 'Colombo';
  String _category = 'Electrical';
  bool _agreeTerms = false;
  bool _isSubmitting = false;

  final _districts = const [
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Galle',
    'Matara',
    'Kurunegala',
    'Jaffna',
    'Anuradhapura',
    'Ratnapura',
  ];

  final _categories = const [
    'Electrical',
    'Plumbing',
    'AC Repair',
    'Carpentry',
    'Masonry',
    'Appliance Repair',
    'House Painting',
    'Roofing & Waterproofing',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      final current = widget.initialProfile ?? roleProvider.currentUser;

      final updatedProfile = (current ??
              UserProfile(
                id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                email: 'user@example.com',
                displayName: _nameController.text.trim(),
              ))
          .copyWith(
        displayName: _nameController.text.trim(),
        role: _selectedRole,
        isProfileComplete: true,
        phone: _phoneController.text.trim(),
        district: _district,
        address: _selectedRole == AppRole.customer
            ? _addressController.text.trim()
            : null,
        nic: _selectedRole == AppRole.provider
            ? _nicController.text.trim()
            : null,
        serviceCategory: _selectedRole == AppRole.provider ? _category : null,
      );

      await roleProvider.completeUserProfile(updatedProfile);

      if (!mounted) return;

      if (_selectedRole == AppRole.customer) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NicVerificationScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final profile = widget.initialProfile ?? roleProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.outline.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.primaryContainer.withOpacity(0.15),
                        backgroundImage: profile?.photoUrl != null
                            ? NetworkImage(profile!.photoUrl!)
                            : null,
                        child: profile?.photoUrl == null
                            ? Text(
                                (profile?.displayName.isNotEmpty == true
                                        ? profile!.displayName[0]
                                        : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile?.displayName ?? 'Google User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle,
                                    color: AppColors.primary, size: 16),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile?.email ?? 'Google account linked',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Google Linked',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'How would you like to use HelaService?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your account type. You can easily manage this later.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _RoleSelectCard(
                        title: 'I need services',
                        subtitle: 'Hire verified technicians',
                        role: AppRole.customer,
                        icon: Icons.roofing_outlined,
                        badgeText: 'Customer',
                        isSelected: _selectedRole == AppRole.customer,
                        onTap: () {
                          setState(() => _selectedRole = AppRole.customer);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleSelectCard(
                        title: 'I offer services',
                        subtitle: 'Get job requests & earn',
                        role: AppRole.provider,
                        icon: Icons.handyman_outlined,
                        badgeText: 'Provider',
                        isSelected: _selectedRole == AppRole.provider,
                        onTap: () {
                          setState(() => _selectedRole = AppRole.provider);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      _selectedRole == AppRole.customer
                          ? 'Customer Details'
                          : 'Service Provider Details',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 1,
                      color: AppColors.outline.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _TextFormField(
                  label: _selectedRole == AppRole.customer
                      ? 'Full Name'
                      : 'Full Name (as on NIC)',
                  controller: _nameController,
                  hintText: 'e.g. Kasun Fernando',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                _TextFormField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  hintText: '77 123 4567',
                  icon: Icons.phone_outlined,
                  prefixText: '+94 ',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (v.trim().replaceAll(' ', '').length < 9) {
                      return 'Enter a valid 9-digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (_selectedRole == AppRole.customer) ...[
                  _TextFormField(
                    label: 'Home or Work Address',
                    controller: _addressController,
                    hintText: 'e.g. No. 45/2, Lake Road',
                    icon: Icons.location_on_outlined,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Address is required for service dispatch'
                        : null,
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  _TextFormField(
                    label: 'National Identity Card (NIC)',
                    controller: _nicController,
                    hintText: 'e.g. 199512345678 or 951234567V',
                    icon: Icons.badge_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'NIC number is required for verification';
                      }
                      final trimmed = v.trim();
                      if (trimmed.length < 10) {
                        return 'Enter a valid Sri Lankan NIC number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Service Trade',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.outline.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _category,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _category = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedRole == AppRole.customer
                          ? 'Your District'
                          : 'Service Operating District',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.outline.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _district,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _districts
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _district = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() => _agreeTerms = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _agreeTerms = !_agreeTerms);
                        },
                        child: Text(
                          _selectedRole == AppRole.customer
                              ? 'I agree to the HelaService Terms of Service and Customer Privacy Policy.'
                              : 'I agree to the Provider Code of Conduct, Background Check verification and Terms of Service.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                PrimaryButton(
                  label: _selectedRole == AppRole.customer
                      ? 'Complete & Explore Services'
                      : 'Continue to NIC Verification',
                  trailingIcon: Icons.arrow_forward,
                  loading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final AppRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outline.withOpacity(0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color:
                        isSelected ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20)
                else
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.outline.withOpacity(0.4)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withOpacity(0.2)
                    : AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final String? prefixText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _TextFormField({
    required this.label,
    required this.controller,
    required this.hintText,
    this.icon,
    this.prefixText,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.onSurface,
            ),
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: AppColors.outline)
                : null,
            filled: true,
            fillColor: AppColors.surfaceLowest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: AppColors.outline.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
