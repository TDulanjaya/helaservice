import 'package:flutter/material.dart';
import '../../../models/technician.dart';
import '../../../repositories/technician_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../utils/l10n_extension.dart';

class RateCardSheet extends StatefulWidget {
  final Technician technician;

  const RateCardSheet({super.key, required this.technician});

  static Future<void> show(BuildContext context, Technician technician) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RateCardSheet(technician: technician),
    );
  }

  @override
  State<RateCardSheet> createState() => _RateCardSheetState();
}

class _RateCardSheetState extends State<RateCardSheet> {
  late final TextEditingController _visitFeeController;
  late final TextEditingController _hourlyRateController;
  late final TextEditingController _dailyRateController;
  late final TextEditingController _perKmController;
  late final TextEditingController _emergencyRateController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.technician;
    _visitFeeController = TextEditingController(
      text: t.visitFeeLkr?.toString() ?? (t.baseRateLkr > 0 ? t.baseRateLkr.toString() : ''),
    );
    _hourlyRateController = TextEditingController(
      text: t.hourlyRateLkr > 0 ? t.hourlyRateLkr.toString() : '',
    );
    _dailyRateController = TextEditingController(
      text: t.dailyRateLkr?.toString() ?? '',
    );
    _perKmController = TextEditingController(
      text: t.perKmRateLkr?.toString() ?? '',
    );
    _emergencyRateController = TextEditingController(
      text: t.emergencyRateLkr > 0 ? t.emergencyRateLkr.toString() : '',
    );
  }

  @override
  void dispose() {
    _visitFeeController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _perKmController.dispose();
    _emergencyRateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final visitFee = int.tryParse(_visitFeeController.text.trim());
    final hourly = int.tryParse(_hourlyRateController.text.trim());
    final daily = int.tryParse(_dailyRateController.text.trim());
    final perKm = int.tryParse(_perKmController.text.trim());
    final emergency = int.tryParse(_emergencyRateController.text.trim());

    if (visitFee != null && (visitFee < 0 || visitFee > 20000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.visitFeeRangeError)),
      );
      return;
    }

    if (hourly != null && (hourly < 1 || hourly > 20000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.hourlyRateRangeError)),
      );
      return;
    }

    if (daily != null && (daily < 1 || daily > 100000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.dailyRateRangeError)),
      );
      return;
    }

    if (perKm != null && (perKm < 1 || perKm > 1000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.perKmRateRangeError)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await TechnicianRepository().updateRates(
        widget.technician.id,
        visitFeeLkr: visitFee,
        hourlyRateLkr: hourly,
        dailyRateLkr: daily,
        perKmRateLkr: perKm,
        emergencyRateLkr: emergency,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.rateCardUpdatedSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('updateRateCard error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToUpdateRates), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.myRateCard,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.rateCardSubtitle,
              style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _visitFeeController,
              label: context.l10n.standardVisitFeeWithCurrency,
              hint: context.l10n.visitFeeOptionalHint,
              icon: Icons.meeting_room_outlined,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _hourlyRateController,
              label: context.l10n.hourlyRateWithUnit,
              hint: context.l10n.hourlyRateHint,
              icon: Icons.timer_outlined,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _dailyRateController,
              label: context.l10n.dailyRateWithUnit,
              hint: context.l10n.dailyRateHint,
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _perKmController,
              label: context.l10n.travelRateWithUnit,
              hint: context.l10n.perKmRateHint,
              icon: Icons.directions_car_outlined,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _emergencyRateController,
              label: context.l10n.emergencyCalloutRate,
              hint: context.l10n.hintAmount,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: context.l10n.saveRates,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            prefixText: 'LKR ',
            filled: true,
            fillColor: context.themeSurfaceLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.themeBorder),
            ),
          ),
        ),
      ],
    );
  }
}
