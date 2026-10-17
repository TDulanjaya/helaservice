import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;
import '../../../constants/firestore_paths.dart';
import '../../../theme/app_theme.dart';
import '../../../models/job_request.dart';
import '../../../models/quote.dart';
import '../../../models/technician.dart';
import '../../../services/category_service.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../utils/location_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../state/role_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/provider_pricing_helper.dart';
import '../../shared/widgets/job_media_gallery.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../utils/schedule_helpers.dart';

class SubmitQuoteSheet extends StatefulWidget {
  final JobRequest jobRequest;

  const SubmitQuoteSheet({super.key, required this.jobRequest});

  @override
  State<SubmitQuoteSheet> createState() => _SubmitQuoteSheetState();
}

class _SubmitQuoteSheetState extends State<SubmitQuoteSheet> {
  // quote type
  String _selectedQuoteType = 'firm';

  // billing unit
  String _selectedPriceUnit = 'fixed';

  final _unitRateController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _materialsController = TextEditingController(text: '0');
  final _visitFeeController = TextEditingController();
  final _travelKmController = TextEditingController(text: '0.0');
  final _travelRateController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedEta = 30;
  bool _submitting = false;
  bool _loadingRates = true;
  bool _isEstimatedTravelKm = false;
  bool _addTravelCost = false;
  Technician? _technician;

  // flexible scheduling proposal
  DateTime? _proposedDate;
  String _proposedSlot = ScheduleHelpers.slotMorning;
  TimeOfDay? _proposedFromTime;
  TimeOfDay? _proposedToTime;
  List<Booking> _activeBookings = [];
  bool _hasClash = false;

  static const List<int> _etaOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    final req = widget.jobRequest;
    if (req.scheduleMode == 'flexible') {
      final minDate = req.scheduledStartAt ?? req.createdAt ?? DateTime.now();
      _proposedDate = DateTime(minDate.year, minDate.month, minDate.day);
      final todayZero = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (_proposedDate!.isBefore(todayZero)) {
        _proposedDate = todayZero;
      }
    }
    _loadTechnicianRates();
  }

  void _prefillUnitRate(String unit, Technician tech) {
    if (unit == 'fixed') {
      _quantityController.text = '1';
      final prefill = ProviderPricingHelper.resolveFixedPricePrefill(
          baseRateLkr: tech.baseRateLkr);
      _unitRateController.text = prefill != null ? '$prefill' : '';
    } else if (unit == 'hour') {
      _unitRateController.text =
          tech.hourlyRateLkr > 0 ? '${tech.hourlyRateLkr}' : '';
    } else if (unit == 'day') {
      _unitRateController.text =
          (tech.dailyRateLkr != null && tech.dailyRateLkr! > 0)
              ? '${tech.dailyRateLkr}'
              : '';
    }
  }

  void _calculateEstimatedDistance(Technician tech, dynamic profile) {
    final req = widget.jobRequest;
    final eff = tech.effectiveLocation;
    final pLat = eff.latitude ?? profile?.latitude;
    final pLng = eff.longitude ?? profile?.longitude;
    if (pLat != null &&
        pLng != null &&
        req.latitude != null &&
        req.longitude != null) {
      final directKm = LocationUtils.calculateDistanceKm(
        pLat,
        pLng,
        req.latitude!,
        req.longitude!,
      );
      final estKm = (directKm * 1.3).clamp(0.0, 200.0);
      _travelKmController.text = estKm.toStringAsFixed(1);
      _isEstimatedTravelKm = true;
    } else {
      _travelKmController.text = '0.0';
      _isEstimatedTravelKm = false;
    }
  }

  Future<void> _loadTechnicianRates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tech = await TechnicianRepository().getById(user.uid);
      final profile = await UserRepository().getUserById(user.uid);
      if (mounted && tech != null) {
        _technician = tech;
        final modes = tech.resolvedPricingModes;

        // initial unit selection based on provider's saved modes
        if (modes.contains(ProviderPricingHelper.modeJob)) {
          _selectedPriceUnit = 'fixed';
        } else if (modes.contains(ProviderPricingHelper.modeHour)) {
          _selectedPriceUnit = 'hour';
        } else if (modes.contains(ProviderPricingHelper.modeDay)) {
          _selectedPriceUnit = 'day';
        } else {
          _selectedPriceUnit = 'fixed';
        }
        _prefillUnitRate(_selectedPriceUnit, tech);

        // fill default visit fee
        final fee = tech.effectiveVisitFeeLkr;
        _visitFeeController.text = fee > 0 ? '$fee' : '';

        // travel setup
        final hasSavedTravel =
            tech.perKmRateLkr != null && tech.perKmRateLkr! > 0;
        _addTravelCost = hasSavedTravel;
        if (hasSavedTravel) {
          _travelRateController.text = '${tech.perKmRateLkr}';
        } else {
          _travelRateController.text = '';
        }
        _calculateEstimatedDistance(tech, profile);
      }
      try {
        _activeBookings =
            await BookingRepository().getActiveBookingsForProvider(user.uid);
      } catch (_) {}
      if (mounted) {
        _checkClash();
      }
    }
    if (mounted) {
      setState(() => _loadingRates = false);
    }
  }

  void _checkClash() {
    if (_activeBookings.isEmpty) {
      if (_hasClash) setState(() => _hasClash = false);
      return;
    }

    DateTime? targetStart;
    DateTime? targetEnd;

    if (widget.jobRequest.scheduleMode == 'flexible') {
      if (_proposedDate == null) return;
      final win = ScheduleHelpers.computeScheduleWindow(
        mode: ScheduleHelpers.modeDate,
        date: _proposedDate,
        slot: _proposedSlot,
        fromTime: _proposedFromTime,
        toTime: _proposedToTime,
      );
      targetStart = win.scheduledStartAt;
      targetEnd = win.scheduledEndAt;
    } else {
      targetStart = widget.jobRequest.scheduledStartAt;
      targetEnd = widget.jobRequest.scheduledEndAt;
      if (targetStart == null && widget.jobRequest.scheduledDate != null) {
        final win = ScheduleHelpers.computeScheduleWindow(
          mode: widget.jobRequest.scheduleMode,
          date: widget.jobRequest.scheduledDate,
          slot: widget.jobRequest.scheduledSlot ?? ScheduleHelpers.slotAnytime,
        );
        targetStart = win.scheduledStartAt;
        targetEnd = win.scheduledEndAt;
      }
    }

    if (targetStart == null || targetEnd == null) {
      if (_hasClash) setState(() => _hasClash = false);
      return;
    }

    bool clashFound = false;
    for (final b in _activeBookings) {
      final bWin = ScheduleHelpers.getBookingWindow(b);
      if (ScheduleHelpers.windowsOverlap(
        start1: targetStart,
        end1: targetEnd,
        start2: bWin.startAt,
        end2: bWin.endAt,
      )) {
        clashFound = true;
        break;
      }
    }

    if (_hasClash != clashFound) {
      setState(() => _hasClash = clashFound);
    }
  }

  @override
  void dispose() {
    _unitRateController.dispose();
    _quantityController.dispose();
    _materialsController.dispose();
    _visitFeeController.dispose();
    _travelKmController.dispose();
    _travelRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _travelCostLkr {
    if (!_addTravelCost) return 0;
    final km = (double.tryParse(_travelKmController.text.trim()) ?? 0.0)
        .clamp(0.0, 200.0);
    final rate =
        (int.tryParse(_travelRateController.text.trim()) ?? 0).clamp(0, 1000);
    return (km * rate).round();
  }

  int get _calculatedQuotedPrice {
    if (_selectedQuoteType == 'inspect') {
      final visit = int.tryParse(_visitFeeController.text.trim()) ?? 0;
      return visit + _travelCostLkr;
    } else {
      final unit = int.tryParse(_unitRateController.text.trim()) ?? 0;
      final qty = _selectedPriceUnit == 'fixed'
          ? 1.0
          : (double.tryParse(_quantityController.text.trim()) ?? 1.0);
      final materials = int.tryParse(_materialsController.text.trim()) ?? 0;
      return (unit * qty).round() + materials + _travelCostLkr;
    }
  }

  String _etaLabel(BuildContext context, int mins) {
    if (mins < 60) return context.l10n.durationMins(mins);
    if (mins == 60) return context.l10n.durationHours(1);
    if (mins == 90) return context.l10n.durationOneAndHalfHours;
    if (mins == 120) return context.l10n.durationHours(2);
    return context.l10n.provDurationHoursMins(mins ~/ 60, mins % 60);
  }

  Future<void> _submit() async {
    final notes = _notesController.text.trim();
    if (notes.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notesLimit500)),
      );
      return;
    }

    final travelKm = _addTravelCost
        ? (double.tryParse(_travelKmController.text.trim()) ?? 0.0)
            .clamp(0.0, 200.0)
        : 0.0;
    final travelRate = _addTravelCost
        ? (int.tryParse(_travelRateController.text.trim()) ?? 0).clamp(0, 1000)
        : 0;
    final travelCost = (travelKm * travelRate).round();

    int? unitRate;
    double? quantity;
    int? materials;
    int visitFee = 0;
    int quotedPrice = 0;

    if (_selectedQuoteType == 'inspect') {
      final visit = int.tryParse(_visitFeeController.text.trim());
      if (visit == null || visit <= 0 || visit > 20000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.quoteInspectVisitFeePrompt)),
        );
        return;
      }
      visitFee = visit;
      quotedPrice = visitFee + travelCost;
    } else {
      final uRate = int.tryParse(_unitRateController.text.trim());
      if (uRate == null || uRate < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.validUnitRatePrompt)),
        );
        return;
      }
      if (_selectedPriceUnit == 'fixed') {
        _quantityController.text = '1';
      }
      final qty = _selectedPriceUnit == 'fixed'
          ? 1.0
          : double.tryParse(_quantityController.text.trim());
      if (qty == null || qty < 0.5 || qty > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.validQuantityPrompt)),
        );
        return;
      }
      final mat = int.tryParse(_materialsController.text.trim()) ?? 0;
      if (mat < 0 || mat > 1000000) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.materialsEstimateLimit)),
        );
        return;
      }

      unitRate = uRate;
      quantity = qty;
      materials = mat;
      visitFee = 0;
      quotedPrice = (unitRate * quantity).round() + materials + travelCost;
    }

    if (quotedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterValidPriceError)),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      final profile = roleProvider.currentUser;

      final defaultProviderName = context.l10n.roleServiceProvider;
      String providerLocation = profile?.district?.trim() ?? '';
      String providerTrade = profile?.serviceCategory ?? '';

      try {
        final techDoc = await FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(user.uid)
            .get();
        if (techDoc.exists) {
          final tData = techDoc.data();
          if (tData != null) {
            final isApproved =
                tData['nicVerified'] == true || tData['isVerified'] == true;
            if (!isApproved) {
              throw Exception(
                  'Your provider profile is pending admin approval.');
            }
            if (providerLocation.isEmpty) {
              providerLocation = (tData['serviceArea'] as String?) ??
                  (tData['district'] as String?) ??
                  '';
            }
            if (providerTrade.isEmpty) {
              providerTrade = (tData['category'] as String?) ?? '';
            }
          }
        }
      } catch (e) {
        if (e.toString().contains('pending admin approval')) rethrow;
      }

      DateTime? pStart;
      DateTime? pEnd;
      String? pSlot;

      if (widget.jobRequest.scheduleMode == 'flexible') {
        if (_proposedDate == null) {
          throw Exception('Please select a proposed arrival date.');
        }
        final win = ScheduleHelpers.computeScheduleWindow(
          mode: ScheduleHelpers.modeDate,
          date: _proposedDate,
          slot: _proposedSlot,
          fromTime: _proposedFromTime,
          toTime: _proposedToTime,
        );
        if (!win.isValid ||
            win.scheduledStartAt == null ||
            win.scheduledEndAt == null) {
          throw Exception(win.errorMessage ?? 'Invalid schedule selection.');
        }
        if (widget.jobRequest.scheduledStartAt != null &&
            win.scheduledStartAt!
                .isBefore(widget.jobRequest.scheduledStartAt!)) {
          throw Exception(
              'Proposed arrival is before customer’s available window.');
        }
        if (widget.jobRequest.scheduledEndAt != null &&
            win.scheduledEndAt!.isAfter(widget.jobRequest.scheduledEndAt!)) {
          throw Exception(
              'Proposed arrival is after customer’s available window.');
        }
        pStart = win.scheduledStartAt;
        pEnd = win.scheduledEndAt;
        pSlot = _proposedSlot;
      }

      final quote = Quote(
        requestId: widget.jobRequest.id,
        providerId: user.uid,
        createdBy: user.uid,
        providerName: profile?.displayName.isNotEmpty == true
            ? profile!.displayName
            : defaultProviderName,
        providerTrade: providerTrade,
        providerLocation: providerLocation,
        quotedPrice: quotedPrice.toDouble(),
        etaMinutes: _selectedEta,
        notes: notes,
        proposedStartAt: pStart,
        proposedEndAt: pEnd,
        proposedSlot: pSlot,
        quoteType: _selectedQuoteType,
        priceUnit: _selectedQuoteType == 'inspect' ? null : _selectedPriceUnit,
        unitRateLkr: unitRate,
        quantity: quantity,
        materialsEstimateLkr: materials,
        visitFeeLkr: visitFee,
        travelKm: travelKm,
        travelRateLkr: travelRate,
        travelCostLkr: travelCost,
      );

      await JobRequestRepository().submitQuote(widget.jobRequest.id, quote);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.quoteSubmittedSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToSubmitQuote(
                e.toString() == 'Exception: Not logged in'
                    ? context.l10n.provNotLoggedIn
                    : e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.jobRequest;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.themeBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.submitPriceQuote,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.submitPriceQuoteSub,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.themeSurfaceLow,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Job Summary Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                CategoryService.instance
                                    .nameOf(req.category, context: context),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (req.customerName.isNotEmpty) ...[
                          Icon(Icons.person_outline_rounded,
                              size: 13, color: context.themeTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            req.customerName,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      req.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (req.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        req.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                    if (req.photos.isNotEmpty ||
                        req.video != null ||
                        req.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      JobMediaGallery(
                        photos: req.photos,
                        video: req.video,
                        legacyPhotoUrls: req.photoUrls,
                      ),
                    ],
                    if (req.address.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              req.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (req.scheduleMode == 'flexible') ...[
                const SizedBox(height: 18),
                const Text(
                  'When can you come?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer is flexible within ${req.scheduleLabel(context)}. Pick your proposed date and time slot.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.themeTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final firstDate =
                        req.scheduledStartAt ?? req.createdAt ?? DateTime.now();
                    final lastDate = req.scheduledEndAt ??
                        firstDate
                            .add(Duration(days: req.flexibleWindowDays ?? 7));
                    final initial = _proposedDate ?? firstDate;
                    final validInitial = initial.isBefore(firstDate)
                        ? firstDate
                        : (initial.isAfter(lastDate) ? lastDate : initial);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: validInitial,
                      firstDate: DateTime(
                          firstDate.year, firstDate.month, firstDate.day),
                      lastDate:
                          DateTime(lastDate.year, lastDate.month, lastDate.day),
                    );
                    if (picked != null) {
                      setState(() => _proposedDate = picked);
                      _checkClash();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _proposedDate != null
                                ? ScheduleHelpers.formatDate(_proposedDate!)
                                : 'Select proposed date',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: context.themeTextSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildSlotChip(
                        ScheduleHelpers.slotMorning, 'Morning (8-12)'),
                    const SizedBox(width: 8),
                    _buildSlotChip(
                        ScheduleHelpers.slotAfternoon, 'Afternoon (12-16)'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSlotChip(
                        ScheduleHelpers.slotEvening, 'Evening (16-20)'),
                    const SizedBox(width: 8),
                    _buildSlotChip(ScheduleHelpers.slotExact, 'Exact Time'),
                  ],
                ),
                if (_proposedSlot == ScheduleHelpers.slotExact) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _proposedFromTime ??
                                  const TimeOfDay(hour: 9, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _proposedFromTime = picked);
                              _checkClash();
                            }
                          },
                          child: Text(_proposedFromTime != null
                              ? 'From: ${_proposedFromTime!.format(context)}'
                              : 'Select From'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _proposedToTime ??
                                  const TimeOfDay(hour: 11, minute: 0),
                            );
                            if (picked != null) {
                              setState(() => _proposedToTime = picked);
                              _checkClash();
                            }
                          },
                          child: Text(_proposedToTime != null
                              ? 'To: ${_proposedToTime!.format(context)}'
                              : 'Select To'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],

              if (_hasClash) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You already have a job at this time.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: context.themeTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // quote type options
              Text(
                context.l10n.quoteType,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildTypeTab('firm', context.l10n.quoteTypeFirm,
                      Icons.verified_rounded),
                  const SizedBox(width: 8),
                  _buildTypeTab('estimate', context.l10n.quoteTypeEstimate,
                      Icons.tune_rounded),
                  const SizedBox(width: 8),
                  _buildTypeTab('inspect', context.l10n.quoteTypeInspect,
                      Icons.search_rounded),
                ],
              ),

              const SizedBox(height: 20),

              if (_loadingRates)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Fields depending on Quote Type
                if (_selectedQuoteType == 'inspect') ...[
                  // Inspect Mode
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.inspectionQuoteNotice,
                            style: TextStyle(
                                fontSize: 12, color: context.themeTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.standardVisitFee,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _visitFeeController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration(
                        prefixText: 'LKR ', hintText: context.l10n.hintAmount),
                  ),
                ] else ...[
                  // standard pricing fields
                  if (_selectedPriceUnit == 'fixed') ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.billingUnit,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.themeTextPrimary),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPriceUnit,
                          decoration: _inputDecoration(),
                          items: _buildUnitDropdownItems(context),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPriceUnit = val;
                                if (_selectedPriceUnit == 'fixed') {
                                  _quantityController.text = '1';
                                }
                                if (_technician != null) {
                                  _prefillUnitRate(val, _technician!);
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.billingUnit,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.themeTextPrimary),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPriceUnit,
                                decoration: _inputDecoration(),
                                items: _buildUnitDropdownItems(context),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedPriceUnit = val;
                                      if (_selectedPriceUnit == 'fixed') {
                                        _quantityController.text = '1';
                                      }
                                      if (_technician != null) {
                                        _prefillUnitRate(val, _technician!);
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.quantityWithUnit(
                                  _selectedPriceUnit == 'hour'
                                      ? context.l10n.unitHours
                                      : context.l10n.unitDays,
                                ),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.themeTextPrimary),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: _inputDecoration(hintText: '1.0'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.unitRateLkr,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _unitRateController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration(
                        prefixText: 'LKR ',
                        hintText: context.l10n.quoteRateForJobHint),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.quoteIncludeVisitCostHint,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.materialsEstimateOptional,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _materialsController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration:
                        _inputDecoration(prefixText: 'LKR ', hintText: '0'),
                  ),
                ],

                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _addTravelCost,
                  title: Text(
                    context.l10n.quoteAddTravelCost,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _addTravelCost = val;
                      if (val && _travelRateController.text.trim().isEmpty) {
                        final rate = _technician?.perKmRateLkr;
                        if (rate != null && rate > 0) {
                          _travelRateController.text = '$rate';
                        }
                      }
                    });
                  },
                ),
                if (_addTravelCost) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  context.l10n.estDistanceKm,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: context.themeTextPrimary),
                                ),
                                if (_isEstimatedTravelKm) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      context.l10n.estimatedLabel,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _travelKmController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDecoration(hintText: '0.0'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.travelRateLkrKm,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.themeTextPrimary),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _travelRateController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDecoration(
                                  hintText: context.l10n.hintAmount),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // summary and total card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Column(
                    children: [
                      if (_selectedQuoteType != 'inspect') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Base (${_quantityController.text} × LKR ${_unitRateController.text})',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: context.themeTextSecondary),
                            ),
                            Text(
                              'LKR ${((double.tryParse(_quantityController.text) ?? 1.0) * (int.tryParse(_unitRateController.text) ?? 0)).round()}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if ((int.tryParse(_materialsController.text) ?? 0) >
                            0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.materialsEstimateColon,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: context.themeTextSecondary),
                              ),
                              Text(
                                'LKR ${int.tryParse(_materialsController.text) ?? 0}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.standardVisitFee,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: context.themeTextSecondary),
                            ),
                            Text(
                              'LKR ${int.tryParse(_visitFeeController.text) ?? 0}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      if (_travelCostLkr > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${context.l10n.travelFee} (${_travelKmController.text} km @ LKR ${_travelRateController.text}/km)',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: context.themeTextSecondary),
                            ),
                            Text(
                              'LKR $_travelCostLkr',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.totalQuotedPrice,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'LKR $_calculatedQuotedPrice',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Text(
                context.l10n.estimatedArrivalTime,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _etaOptions.map((mins) {
                  final selected = _selectedEta == mins;
                  return InkWell(
                    onTap: () => setState(() => _selectedEta = mins),
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? (context.isDark ? Colors.white : Colors.black)
                            : context.themeSurfaceLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : context.themeBorder,
                        ),
                      ),
                      child: Text(
                        _etaLabel(context, mins),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? (context.isDark ? Colors.black : Colors.white)
                              : context.themeTextPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              Text(
                context.l10n.messageToCustomerOptional,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: context.l10n.quoteNotesHint,
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: context.themeTextSecondary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 24),

              PrimaryButton(
                label: context.l10n.sendQuoteLkr('$_calculatedQuotedPrice'),
                leadingIcon: Icons.send_rounded,
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeTab(String type, String label, IconData icon) {
    final selected = _selectedQuoteType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedQuoteType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : context.themeSurfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : context.themeBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    selected ? AppColors.primary : context.themeTextSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      selected ? AppColors.primary : context.themeTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChip(String slot, String label) {
    final isSelected = _proposedSlot == slot;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _proposedSlot = slot);
          _checkClash();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : context.themeSurfaceLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.themeBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppColors.primary : context.themeTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? prefixText, String? hintText}) {
    return InputDecoration(
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: context.themeTextSecondary,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: context.themeTextSecondary.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: context.themeSurfaceLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.themeBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.themeBorder),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  List<DropdownMenuItem<String>> _buildUnitDropdownItems(BuildContext context) {
    return [
      DropdownMenuItem(
          value: 'fixed', child: Text(context.l10n.billingUnitFixed)),
      DropdownMenuItem(
          value: 'hour', child: Text(context.l10n.billingUnitHour)),
      DropdownMenuItem(value: 'day', child: Text(context.l10n.billingUnitDay)),
    ];
  }
}
