import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../state/role_provider.dart';
import '../../../services/auth_service.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../repositories/category_repository.dart';
import '../../../models/admin_models.dart';
import 'nic_verification_screen.dart';

class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nicController = TextEditingController();
  String _category = 'Electrical';
  String _district = 'Colombo';
  bool _agreed = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

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

  List<String> get _districts => LocationUtils.districtCoordinates.keys.toList();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nic = _nicController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterFullName),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterValidEmail),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.passwordLengthError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (nic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterNicError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim().isNotEmpty
          ? AuthService.formatSriLankanPhoneNumber(_phoneController.text.trim())
          : null;

      final profile = await AuthService().signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
        role: AppRole.provider,
        phone: phone,
        nic: nic,
        serviceCategory: _category,
        district: _district,
      );

      if (!mounted) return;

      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      roleProvider.setUser(profile);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NicVerificationScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.getReadableAuthError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          context.l10n.becomeProvider,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.providerRegisterSubtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  color: context.themeTextSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _Field(
                label: context.l10n.fullNameNicLabel,
                controller: _nameController,
                hint: 'Kasun Perera',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _Field(
                label: context.l10n.accountEmailLabel,
                controller: _emailController,
                hint: 'kasun.provider@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.passwordLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      hintText: context.l10n.atLeast6Chars,
                      hintStyle: TextStyle(color: context.themeTextSecondary),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: context.themeSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: context.themeBorder,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Field(
                label: context.l10n.providerPhoneLabel,
                controller: _phoneController,
                hint: '77 123 4567',
                keyboardType: TextInputType.phone,
                prefixText: '+94 ',
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 14),
              _Field(
                label: context.l10n.nicNumberLabel,
                controller: _nicController,
                hint: '200012345678 or 881234567V',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),
              StreamBuilder<List<CategoryRow>>(
                stream: CategoryRepository().streamCategoryRows(),
                builder: (context, snapshot) {
                  final liveCats = (snapshot.data ?? [])
                      .where((c) => c.status.toLowerCase() == 'active')
                      .map((c) => c.name)
                      .toList();
                  final allCats = liveCats.isNotEmpty ? liveCats : _categories;

                  return _Dropdown(
                    label: context.l10n.primaryCategory,
                    value: allCats.contains(_category) ? _category : allCats.first,
                    items: allCats,
                    itemLabel: (c) => LocalizedData.getCategory(context, c),
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  );
                },
              ),
              const SizedBox(height: 14),
              _Dropdown(
                label: context.l10n.primaryDistrict,
                value: _districts.contains(_district) ? _district : _districts.first,
                items: _districts,
                itemLabel: (d) => LocalizedData.getDistrict(context, d),
                onChanged: (v) => setState(() => _district = v ?? _district),
              ),
              const SizedBox(height: 18),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.l10n.agreeProviderTerms,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.themeTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: context.l10n.createAccountVerifyNic,
                loading: _isLoading,
                onPressed: _agreed ? _createAccount : null,
              ),
              const SizedBox(height: 14),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      context.l10n.alreadyHaveAccount,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        context.l10n.signIn,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
  final IconData? prefixIcon;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefixText,
    this.prefixIcon,
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
            color: context.themeTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: context.themeTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.themeTextSecondary),
            prefixText: prefixText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            filled: true,
            fillColor: context.themeSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: context.themeBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String)? itemLabel;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: context.themeTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.themeBorder,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              dropdownColor: context.themeSurface,
              isExpanded: true,
              items: items
                  .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        itemLabel != null ? itemLabel!(d) : d,
                        style: TextStyle(color: context.themeTextPrimary),
                      )))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
