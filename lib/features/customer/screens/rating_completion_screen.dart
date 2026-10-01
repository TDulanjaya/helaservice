import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/map_launcher.dart';
import '../../../services/review_service.dart';
import '../../../state/role_provider.dart';
import 'home_discovery_screen.dart';

class RatingCompletionScreen extends StatefulWidget {
  final Technician technician;
  final String bookingId;
  final String jobRequestId;
  final String jobTitle;
  final double? totalPrice;

  const RatingCompletionScreen({
    super.key,
    required this.technician,
    this.bookingId = '',
    this.jobRequestId = '',
    this.jobTitle = '',
    this.totalPrice,
  });

  @override
  State<RatingCompletionScreen> createState() => _RatingCompletionScreenState();
}

class _RatingCompletionScreenState extends State<RatingCompletionScreen> {
  int _rating = 5;
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
      appBar: AppBar(title: Text(context.l10n.checkoutBooking)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: context.themeSurfaceContainer, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 10),
              Text(context.l10n.serviceCompleted,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              Text(
                  widget.jobTitle.isNotEmpty
                      ? '${widget.jobTitle} • ${widget.technician.name.split(' ').first}'
                      : widget.technician.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.themeTextSecondary)),
              if (widget.jobRequestId.isNotEmpty)
                Text('Job #${widget.jobRequestId.length > 8 ? widget.jobRequestId.substring(0, 8).toUpperCase() : widget.jobRequestId.toUpperCase()}',
                    style: TextStyle(color: context.themeTextSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04), blurRadius: 12)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.receipt_long,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(context.l10n.costBreakdown,
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                      Text(context.l10n.paid,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ]),
                const Divider(height: 20),
                if (widget.totalPrice != null) ...[              
                  _CostRow(context.l10n.totalPaid, 'LKR ${widget.totalPrice!.toStringAsFixed(0)}', bold: true),
                ] else ...[                  
                  _CostRow(context.l10n.totalPaid, 'Settled directly', bold: true),
                ],
                const SizedBox(height: 6),
                Text(context.l10n.settledDirectlyCash,
                    style: TextStyle(
                        fontSize: 11, color: context.themeTextSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Column(
            children: [
              const Icon(Icons.handyman, color: AppColors.primary, size: 28),
              const SizedBox(height: 6),
              Text('${context.l10n.rateExperience} (${widget.technician.name.split(' ').first})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              RatingStars(
                  rating: _rating.toDouble(),
                  size: 34,
                  onChanged: (v) => setState(() => _rating = v)),
              const SizedBox(height: 6),
              Text(_getRatingLabel(context),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 18),
          Text(context.l10n.whatWentWell,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagOptions.map((opt) {
              final selected = _tags.contains(opt.$2);
              return FilterChip(
                label: Text(_getTagLabel(context, opt.$2)),
                avatar: Icon(opt.$1,
                    size: 16,
                    color:
                        selected ? AppColors.onPrimary : context.themeTextSecondary),
                selected: selected,
                onSelected: (v) => setState(
                    () => v ? _tags.add(opt.$2) : _tags.remove(opt.$2)),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    color: selected ? AppColors.onPrimary : context.themeTextPrimary,
                    fontSize: 12),
                backgroundColor: context.themeSurfaceContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
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
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: context.themeBorder),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            const Icon(Icons.volunteer_activism, color: AppColors.secondaryContainer),
            const SizedBox(width: 6),
            Text(context.l10n.tipProvider,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              _TipChip(
                  label: '+LKR 200',
                  sub: context.l10n.tipSmallTea,
                  selected: _tipLabel == '200',
                  onTap: () => setState(() => _tipLabel = '200')),
              const SizedBox(width: 8),
              _TipChip(
                  label: '+LKR 500',
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
            label: _isSaving ? context.l10n.savingProgress : context.l10n.done,
            trailingIcon: Icons.arrow_forward,
            onPressed: _isSaving ? null : _submitReview,
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: context.themeSurface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.orderPaymentSupport,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.orderSupportDesc,
                            style: TextStyle(fontSize: 12.5, color: context.themeTextSecondary),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.call, color: AppColors.onPrimary, size: 18),
                            ),
                            title: Text(context.l10n.callSupportHotline,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            subtitle: Text(context.l10n.tollFreeCare, style: const TextStyle(fontSize: 11)),
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
                  color:
                      bold ? context.themeTextPrimary : context.themeTextSecondary)),
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
                color: selected ? AppColors.primary : context.themeBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected ? AppColors.primary : context.themeTextPrimary)),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10, color: context.themeTextSecondary)),
          ]),
        ),
      ),
    );
  }
}
