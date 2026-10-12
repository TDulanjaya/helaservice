import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../state/role_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/otp_service.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/auth_error_l10n.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../repositories/category_repository.dart';
import '../../../models/admin_models.dart';
import 'nic_verification_screen.dart';
import '../../auth/screens/email_otp_screen.dart';
import '../../../shared/widgets/searchable_select_picker.dart';

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
  final _dailyRateController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _perKmRateController = TextEditingController();
  final _visitFeeController = TextEditingController();
  String _category = '';
  String _district = 'Colombo';
  bool _agreed = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  List<String> get _districts => LocationUtils.districtCoordinates.keys.toList();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _dailyRateController.dispose();
    _hourlyRateController.dispose();
    _perKmRateController.dispose();
    _visitFeeController.dispose();
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

    final daily = int.tryParse(_dailyRateController.text.trim());
    final hourly = int.tryParse(_hourlyRateController.text.trim());
    final perKm = int.tryParse(_perKmRateController.text.trim());
    final visitFee = int.tryParse(_visitFeeController.text.trim());

    if (daily == null && hourly == null && perKm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.atLeastOneRateRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (daily != null && (daily < 1 || daily > 100000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.dailyRateRangeError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (hourly != null && (hourly < 1 || hourly > 20000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.hourlyRateRangeError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (perKm != null && (perKm < 1 || perKm > 1000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.perKmRateRangeError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (visitFee != null && (visitFee < 0 || visitFee > 20000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.visitFeeRangeError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await OtpService().sendEmailOtp(email);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: email,
            onVerified: () async {
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
                dailyRateLkr: daily,
                hourlyRateLkr: hourly,
                perKmRateLkr: perKm,
                visitFeeLkr: visitFee,
              );

              if (!mounted) return;

              final roleProvider =
                  pv.Provider.of<RoleProvider>(context, listen: false);
              roleProvider.setUser(profile);

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const NicVerificationScreen()),
                (route) => false,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Exception:')
                ? e.toString().replaceFirst('Exception: ', '')
                : authErrorMessage(context, e),
          ),
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
    final isFieldBg = context.isDark ? context.themeSurfaceLow : Colors.white;

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.themeBorder, width: 1.5),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.themeTextPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        title: Text(
          context.l10n.becomeProvider,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.themeTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text(
                context.l10n.providerRegisterSubtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  color: context.themeTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _Field(
                label: context.l10n.fullNameNicLabel,
                controller: _nameController,
                hint: context.l10n.hintFullName,
                prefixIcon: Icons.person_outline,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 16),
              _Field(
                label: context.l10n.accountEmailLabel,
                controller: _emailController,
                hint: context.l10n.hintProviderEmail,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.passwordLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: context.themeTextPrimary, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: context.l10n.atLeast6Chars,
                      hintStyle: TextStyle(
                        color: context.themeTextSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(Icons.lock_outline, size: 20, color: context.themeTextSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: context.themeTextSecondary,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: isFieldBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.themeBorder, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: context.themeBorder, width: 1.5),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Field(
                label: context.l10n.providerPhoneLabel,
                controller: _phoneController,
                hint: '77 123 4567',
                keyboardType: TextInputType.phone,
                prefixText: '+94 ',
                prefixIcon: Icons.phone_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 16),
              _Field(
                label: context.l10n.nicNumberLabel,
                controller: _nicController,
                hint: context.l10n.provNicHintExample,
                prefixIcon: Icons.badge_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<CategoryRow>>(
                stream: CategoryRepository().streamLiveCategories(),
                builder: (context, snapshot) {
                  final liveCats = snapshot.data ?? [];
                  if (liveCats.isEmpty &&
                      snapshot.connectionState != ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.themeSurfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Text(
                        context.l10n.noServicesAvailableYet,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    );
                  }

                  final effectiveVal = liveCats.any((c) => c.id == _category)
                      ? _category
                      : (liveCats.isNotEmpty ? liveCats.first.id : '');
                  if (_category.isEmpty && liveCats.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _category.isEmpty) {
                        setState(() => _category = effectiveVal);
                      }
                    });
                  }

                  return SearchableSelectPicker<String>(
                    label: context.l10n.primaryCategory,
                    selectedValue: effectiveVal.isNotEmpty ? effectiveVal : null,
                    prefixIcon: Icons.bolt_outlined,
                    isDarkField: context.isDark,
                    modalTitle: context.l10n.category,
                    searchHint: context.l10n.searchCategoryHint,
                    items: liveCats.map((c) {
                      return SearchableSelectItem<String>(
                        value: c.id,
                        label: c.name,
                        icon: c.icon,
                        searchTerms: [c.name, c.id],
                      );
                    }).toList(),
                    onSelected: (v) => setState(() => _category = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              SearchableSelectPicker<String>(
                label: context.l10n.primaryDistrict,
                selectedValue: _districts.contains(_district) ? _district : _districts.first,
                prefixIcon: Icons.map_outlined,
                isDarkField: context.isDark,
                modalTitle: context.l10n.district,
                searchHint: context.l10n.searchDistrictHint,
                items: _districts.map((d) {
                  final localizedName = LocalizedData.getDistrict(context, d);
                  final sin = LocalizedData.districts[d]?['si'] ?? '';
                  final tam = LocalizedData.districts[d]?['ta'] ?? '';
                  return SearchableSelectItem<String>(
                    value: d,
                    label: localizedName,
                    subtitle: localizedName != d ? d : null,
                    icon: Icons.location_on_outlined,
                    searchTerms: [d, sin, tam],
                  );
                }).toList(),
                onSelected: (v) => setState(() => _district = v),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.yourUsualRates,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.yourUsualRatesSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: context.themeTextSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _Field(
                label: context.l10n.dailyRate,
                controller: _dailyRateController,
                hint: context.l10n.dailyRateHint,
                keyboardType: TextInputType.number,
                prefixText: 'LKR ',
                prefixIcon: Icons.calendar_today_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 14),
              _Field(
                label: context.l10n.hourlyRate,
                controller: _hourlyRateController,
                hint: context.l10n.hourlyRateHint,
                keyboardType: TextInputType.number,
                prefixText: 'LKR ',
                prefixIcon: Icons.timer_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 14),
              _Field(
                label: context.l10n.perKmTravelRate,
                controller: _perKmRateController,
                hint: context.l10n.perKmRateHint,
                keyboardType: TextInputType.number,
                prefixText: 'LKR ',
                prefixIcon: Icons.directions_car_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 14),
              _Field(
                label: context.l10n.standardVisitFee,
                controller: _visitFeeController,
                hint: context.l10n.visitFeeOptionalHint,
                keyboardType: TextInputType.number,
                prefixText: 'LKR ',
                prefixIcon: Icons.meeting_room_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                title: Text(
                  context.l10n.agreeProviderTerms,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.themeTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: context.l10n.createAccountVerifyNic,
                loading: _isLoading,
                onPressed: _agreed && !_isLoading ? _createAccount : null,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.alreadyHaveAccount,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: context.themeTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      context.l10n.signIn,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
  final bool isDarkField;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefixText,
    this.prefixIcon,
    required this.isDarkField,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDarkField ? context.themeSurfaceLow : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: context.themeTextPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.themeTextSecondary.withValues(alpha: 0.6),
            ),
            prefixText: prefixText,
            prefixStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: context.themeTextSecondary)
                : null,
            filled: true,
            fillColor: bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: context.themeBorder,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: context.themeBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

