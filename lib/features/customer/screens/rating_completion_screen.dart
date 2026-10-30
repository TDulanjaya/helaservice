import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;
import '../../../constants/firestore_paths.dart';
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/map_launcher.dart';
import '../../../services/review_service.dart';
import '../../../state/role_provider.dart';
import 'home_discovery_screen.dart';

// customer rating screen
class RatingCompletionScreen extends StatefulWidget {
  final Technician technician;
  final String bookingId;
  final String jobRequestId;
  final String jobTitle;
  final double? totalPrice;
  final String? completionType;

  const RatingCompletionScreen({
    super.key,
    required this.technician,
    this.bookingId = '',
    this.jobRequestId = '',
    this.jobTitle = '',
    this.totalPrice,
    this.completionType,
  });

  @override
  State<RatingCompletionScreen> createState() => _RatingCompletionScreenState();
}

class _RatingCompletionScreenState extends State<RatingCompletionScreen> {
  int _rating = 5;
  String? _effectiveCompletionType;
  final _tags = <String>{'Punctual', 'Clean Work'};
  final _tagOptions = const [
    (Icons.schedule, 'Punctual'),
    (Icons.sentiment_satisfied, 'Polite'),
    (Icons.cleaning_services, 'Clean Work'),
    (Icons.sell, 'Fair Price'),
  ];
  String? _tipLabel;
  final _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _effectiveCompletionType = widget.completionType;
    if (_effectiveCompletionType == null && widget.bookingId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection(FirestorePaths.bookings)
          .doc(widget.bookingId)
          .get()
          .then((doc) {
        if (mounted && doc.exists) {
          final t = doc.data()?['completionType'] as String?;
          if (t != null) {
            setState(() => _effectiveCompletionType = t);
          }
        }
      });
    }
  }

  String _getRatingLabel(BuildContext context) {
    switch (_rating) {
      case 5:
        return context.l10n.ratingExceptional;
      case 4:
        return context.l10n.ratingGreat;
      case 3:
        return context.l10n.ratingGood;
      case 2:
        return context.l10n.ratingOkay;
      default:
        return context.l10n.ratingNeedsWork;
    }
  }

  String _getTagLabel(BuildContext context, String key) {
    switch (key) {
      case 'Punctual':
        return context.l10n.tagPunctual;
      case 'Polite':
        return context.l10n.tagPolite;
      case 'Clean Work':
        return context.l10n.tagCleanWork;
      case 'Fair Price':
        return context.l10n.tagFairPrice;
      default:
        return key;
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isSaving = true);

    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final currentUser = roleProvider.currentUser;

    int tipAmount = 0;
    if (_tipLabel == '200') tipAmount = 200;
    if (_tipLabel == '500') tipAmount = 500;

    try {
      await ReviewService.instance.submitReview(
        customerId: currentUser?.id ?? '',
        customerName: currentUser?.displayName ?? '',
        providerId: widget.technician.id,
        jobRequestId: widget.jobRequestId,
        bookingId: widget.bookingId,
        rating: _rating,
        tags: _tags.toList(),
        comment: _commentController.text.trim(),
        tipAmountLkr: tipAmount,
      );
    } catch (_) {}

    if (!mounted) return;

    if (kDebugMode) {
      debugPrint(
          '[navdbg] -> customer home from rating_completion_screen.dart');
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: IconSquareButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        title: Text(context.l10n.checkoutBooking),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF1B382B)
                      : const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: context.isDark
                      ? const Color(0xFF81C784)
                      : const Color(0xFF2E7D32),
                  size: 38,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.serviceCompleted,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                widget.jobTitle.isNotEmpty
                    ? '${widget.jobTitle} • ${widget.technician.name}'
                    : widget.technician.name,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: context.themeTextSecondary, fontSize: 13),
              ),
              if (widget.jobRequestId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    context.l10n.jobIdNumber(widget.jobRequestId.length > 8
                        ? widget.jobRequestId.substring(0, 8).toUpperCase()
                        : widget.jobRequestId.toUpperCase()),
                    style: TextStyle(
                        color: context.themeTextSecondary, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.receipt_long,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.costBreakdown,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xFF1B382B)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        context.l10n.paid,
                        style: TextStyle(
                          color: context.isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF2E7D32),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (widget.totalPrice != null && widget.totalPrice! > 0) ...[
                  _CostRow(context.l10n.totalPaid,
                      'LKR ${widget.totalPrice!.toStringAsFixed(0)}',
                      bold: true),
                ] else ...[
                  _CostRow(context.l10n.totalPaid, context.l10n.settledDirectly,
                      bold: true),
                ],
                const SizedBox(height: 6),
                Text(
                  context.l10n.settledDirectlyCash,
                  style: TextStyle(
                      fontSize: 11, color: context.themeTextSecondary),
                ),
              ],
            ),
          ),
          if (_effectiveCompletionType == 'visit_only') ...[
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.visitOnlyCompletedNote,
                      style: TextStyle(
                          fontSize: 13, color: context.themeTextPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: context.l10n.done,
              trailingIcon: Icons.arrow_forward,
              onPressed: () {
                if (kDebugMode) {
                  debugPrint(
                      '[navdbg] -> customer home from rating_completion_screen.dart');
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const HomeDiscoveryScreen()),
                  (route) => false,
                );
              },
            ),
          ] else ...[
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  UserAvatar(
                    uid: widget.technician.id,
                    displayName: widget.technician.name,
                    radius: 28,
                    backgroundColor: widget.technician.avatarColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${context.l10n.rateExperience} (${widget.technician.name.split(' ').first})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  RatingStars(
                      rating: _rating.toDouble(),
                      size: 36,
                      onChanged: (v) => setState(() => _rating = v)),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingLabel(context),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.whatWentWell,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tagOptions.map((opt) {
                final selected = _tags.contains(opt.$2);
                return FilterChip(
                  label: Text(_getTagLabel(context, opt.$2)),
                  avatar: Icon(opt.$1,
                      size: 16,
                      color: selected
                          ? AppColors.onPrimary
                          : context.themeTextSecondary),
                  selected: selected,
                  onSelected: (v) => setState(
                      () => v ? _tags.add(opt.$2) : _tags.remove(opt.$2)),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: selected
                          ? AppColors.onPrimary
                          : context.themeTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  backgroundColor: context.themeSurfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : context.themeBorder)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: TextStyle(color: context.themeTextPrimary),
              decoration: InputDecoration(
                hintText: context.l10n.leaveReviewOptional,
                hintStyle: TextStyle(color: context.themeTextSecondary),
                filled: true,
                fillColor: context.themeSurface,
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  borderSide:
                      BorderSide(color: context.themeBorder, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  borderSide:
                      BorderSide(color: context.themeBorder, width: 1.5),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              const Icon(Icons.volunteer_activism,
                  color: AppColors.secondaryContainer),
              const SizedBox(width: 6),
              Text(context.l10n.tipProvider,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                _TipChip(
                    label: context.l10n.tip200,
                    sub: context.l10n.tipSmallTea,
                    selected: _tipLabel == '200',
                    onTap: () => setState(() => _tipLabel = '200')),
                const SizedBox(width: 8),
                _TipChip(
                    label: context.l10n.tip500,
                    sub: context.l10n.tipGenerous,
                    selected: _tipLabel == '500',
                    onTap: () => setState(() => _tipLabel = '500')),
                const SizedBox(width: 8),
                _TipChip(
                    label: context.l10n.tipCustom,
                    sub: context.l10n.tipEnterAmount,
                    selected: _tipLabel == 'custom',
                    onTap: () => setState(() => _tipLabel = 'custom')),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label:
                  _isSaving ? context.l10n.savingProgress : context.l10n.done,
              trailingIcon: Icons.arrow_forward,
              onPressed: _isSaving ? null : _submitReview,
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: context.themeSurface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: context.themeBorder,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.orderPaymentSupport,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.orderSupportDesc,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: context.themeTextSecondary),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: context.themeBorder),
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.call,
                                  color: AppColors.onPrimary, size: 18),
                            ),
                            title: Text(context.l10n.callSupportHotline,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                            subtitle: Text(context.l10n.tollFreeCare,
                                style: const TextStyle(fontSize: 11)),
                            onTap: () {
                              Navigator.pop(ctx);
                              MapLauncher.openPhoneCall('1340');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.support_agent, size: 16),
              label: Text(context.l10n.needHelpOrder),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _CostRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        fontSize: bold ? 15 : 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Text(label,
              style: style.copyWith(
                  color: bold
                      ? context.themeTextPrimary
                      : context.themeTextSecondary)),
        ),
        const SizedBox(width: 8),
        Text(value, style: style),
      ]),
    );
  }
}

class _TipChip extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _TipChip(
      {required this.label,
      required this.sub,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : context.themeSurface,
            border: Border.all(
                color: selected ? AppColors.primary : context.themeBorder,
                width: selected ? 1.5 : 1.0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected
                        ? AppColors.primary
                        : context.themeTextPrimary)),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 10, color: context.themeTextSecondary)),
          ]),
        ),
      ),
    );
  }
}
