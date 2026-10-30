import 'package:flutter/material.dart';
import '../../../models/technician.dart';
import '../../../repositories/technician_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/provider_pricing_helper.dart';

// rate card sheet for service pricing
class RateCardSheet extends StatefulWidget {
  final Technician technician;
  final String? initialSelectedMode;

  const RateCardSheet({
    super.key,
    required this.technician,
    this.initialSelectedMode,
  });

  static Future<bool?> show(
    BuildContext context,
    Technician technician, {
    String? initialSelectedMode,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RateCardSheet(
        technician: technician,
        initialSelectedMode: initialSelectedMode,
      ),
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
  late List<String> _pricingModes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.technician;
    _pricingModes = List<String>.from(t.resolvedPricingModes);
    if (widget.initialSelectedMode != null &&
        !_pricingModes.contains(widget.initialSelectedMode)) {
      _pricingModes.add(widget.initialSelectedMode!);
    }
    _visitFeeController = TextEditingController(
      text: t.visitFeeLkr?.toString() ??
          (t.baseRateLkr > 0 ? t.baseRateLkr.toString() : ''),
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
  }

  @override
  void dispose() {
    _visitFeeController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _perKmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!ProviderPricingHelper.hasBasePricingMode(_pricingModes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.atLeastOneBasePricingModeRequired)),
      );
      return;
    }

    int? visitFee;
    if (_pricingModes.contains(ProviderPricingHelper.modeVisit)) {
      visitFee = int.tryParse(_visitFeeController.text.trim());
      final minFee = widget.technician.emergencyAvailable
          ? 1
          : ProviderPricingHelper.minVisitFee;
      if (visitFee == null ||
          visitFee < minFee ||
          visitFee > ProviderPricingHelper.maxVisitFee) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.technician.emergencyAvailable
                  ? context.l10n.visitFeeEmergencyRangeError
                  : context.l10n.visitFeeRangeError,
            ),
          ),
        );
        return;
      }
    }

    int? hourly;
    if (_pricingModes.contains(ProviderPricingHelper.modeHour)) {
      hourly = int.tryParse(_hourlyRateController.text.trim());
      if (hourly == null ||
          hourly < ProviderPricingHelper.minHourlyRate ||
          hourly > ProviderPricingHelper.maxHourlyRate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.hourlyRateRangeError)),
        );
        return;
      }
    }

    int? daily;
    if (_pricingModes.contains(ProviderPricingHelper.modeDay)) {
      daily = int.tryParse(_dailyRateController.text.trim());
      if (daily == null ||
          daily < ProviderPricingHelper.minDailyRate ||
          daily > ProviderPricingHelper.maxDailyRate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.dailyRateRangeError)),
        );
        return;
      }
    }

    int? perKm;
    if (_pricingModes.contains(ProviderPricingHelper.modeTravel)) {
      perKm = int.tryParse(_perKmController.text.trim());
      if (perKm == null ||
          perKm < ProviderPricingHelper.minPerKmRate ||
          perKm > ProviderPricingHelper.maxPerKmRate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.perKmRateRangeError)),
        );
        return;
      }
    }

    final int newVisitFee =
        (_pricingModes.contains(ProviderPricingHelper.modeVisit) &&
                (visitFee ?? 0) > 0)
            ? visitFee!
            : 0;
    final bool turningEmergencyOff =
        widget.technician.emergencyAvailable && newVisitFee == 0;

    if (turningEmergencyOff) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(context.l10n.removeVisitFeeEmergencyConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(context.l10n.continueText),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _saving = true);
    try {
      await TechnicianRepository().updateRates(
        widget.technician.id,
        pricingModes: _pricingModes,
        visitFeeLkr: visitFee,
        hourlyRateLkr: hourly,
        dailyRateLkr: daily,
        perKmRateLkr: perKm,
      );
      if (turningEmergencyOff) {
        await TechnicianRepository().updateEmergencyStatus(
          widget.technician.id,
          false,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
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
          SnackBar(
              content: Text(context.l10n.failedToUpdateRates),
              backgroundColor: AppColors.error),
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
              context.l10n.howDoYouChargeTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.howDoYouChargeSubtitle,
              style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _pricingModes.contains(ProviderPricingHelper.modeHour),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _pricingModes.add(ProviderPricingHelper.modeHour);
                  } else {
                    _pricingModes.remove(ProviderPricingHelper.modeHour);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              title: Text(
                context.l10n.pricingModePerHour,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (_pricingModes.contains(ProviderPricingHelper.modeHour)) ...[
              const SizedBox(height: 4),
              _buildField(
                controller: _hourlyRateController,
                label: context.l10n.hourlyRateWithUnit,
                hint: context.l10n.hourlyRateHint,
                icon: Icons.timer_outlined,
              ),
              const SizedBox(height: 12),
            ],
            CheckboxListTile(
              value: _pricingModes.contains(ProviderPricingHelper.modeDay),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _pricingModes.add(ProviderPricingHelper.modeDay);
                  } else {
                    _pricingModes.remove(ProviderPricingHelper.modeDay);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              title: Text(
                context.l10n.pricingModePerDay,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (_pricingModes.contains(ProviderPricingHelper.modeDay)) ...[
              const SizedBox(height: 4),
              _buildField(
                controller: _dailyRateController,
                label: context.l10n.dailyRateWithUnit,
                hint: context.l10n.dailyRateHint,
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 12),
            ],
            CheckboxListTile(
              value: _pricingModes.contains(ProviderPricingHelper.modeJob),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _pricingModes.add(ProviderPricingHelper.modeJob);
                  } else {
                    _pricingModes.remove(ProviderPricingHelper.modeJob);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              title: Text(
                context.l10n.pricingModePricePerJob,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _pricingModes.contains(ProviderPricingHelper.modeVisit),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _pricingModes.add(ProviderPricingHelper.modeVisit);
                  } else {
                    _pricingModes.remove(ProviderPricingHelper.modeVisit);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              title: Text(
                context.l10n.pricingModeVisitFee,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (_pricingModes.contains(ProviderPricingHelper.modeVisit)) ...[
              const SizedBox(height: 4),
              _buildField(
                controller: _visitFeeController,
                label: context.l10n.standardVisitFeeWithCurrency,
                hint: widget.technician.emergencyAvailable
                    ? context.l10n.visitFeeEmergencyHint
                    : context.l10n.visitFeeOptionalHint,
                icon: Icons.meeting_room_outlined,
              ),
              const SizedBox(height: 12),
            ],
            CheckboxListTile(
              value: _pricingModes.contains(ProviderPricingHelper.modeTravel),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _pricingModes.add(ProviderPricingHelper.modeTravel);
                  } else {
                    _pricingModes.remove(ProviderPricingHelper.modeTravel);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              title: Text(
                context.l10n.pricingModeTravelPerKm,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (_pricingModes.contains(ProviderPricingHelper.modeTravel)) ...[
              const SizedBox(height: 4),
              _buildField(
                controller: _perKmController,
                label: context.l10n.travelRateWithUnit,
                hint: context.l10n.perKmRateHint,
                icon: Icons.directions_car_outlined,
              ),
              const SizedBox(height: 12),
            ],
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
