import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/technician.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/primary_button.dart';
import 'home_discovery_screen.dart';

class RatingCompletionScreen extends StatefulWidget {
  final Technician technician;
  const RatingCompletionScreen({super.key, required this.technician});

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

  String get _ratingLabel {
    switch (_rating) {
      case 5:
        return 'Exceptional! 5.0';
      case 4:
        return 'Great, 4.0';
      case 3:
        return 'Good, 3.0';
      case 2:
        return 'Okay, 2.0';
      default:
        return 'Needs work, 1.0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: AppColors.surfaceHigh, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 10),
              const Text('Service Completed! 🎉',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              Text(
                  'Water Pump & Valve Overhaul finished by ${widget.technician.name.split(' ').first}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
              const Text('Job ID #HL-89421',
                  style: TextStyle(color: AppColors.outline, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 12)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(children: [
                        Icon(Icons.receipt_long,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('Cost Breakdown',
                            style: TextStyle(fontWeight: FontWeight.bold))
                      ]),
                      Text('PAID',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ]),
                const Divider(height: 20),
                const _CostRow('Base diagnostic & visit', 'LKR 1,500'),
                const _CostRow('Parts & labor', 'LKR 2,200'),
                const Divider(height: 20),
                const _CostRow('Total Paid', 'LKR 3,700', bold: true),
                const SizedBox(height: 6),
                const Text('Settled via LankaQR / Cash on site',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Column(
            children: [
              const Icon(Icons.handyman, color: AppColors.primary, size: 28),
              const SizedBox(height: 6),
              Text("Rate ${widget.technician.name.split(' ').first}'s Service",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('Tap a star to rate your overall repair experience',
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 10),
              RatingStars(
                  rating: _rating.toDouble(),
                  size: 34,
                  onChanged: (v) => setState(() => _rating = v)),
              const SizedBox(height: 6),
              Text(_ratingLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 18),
          const Text('What went especially well?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagOptions.map((opt) {
              final selected = _tags.contains(opt.$2);
              return FilterChip(
                label: Text(opt.$2),
                avatar: Icon(opt.$1,
                    size: 16,
                    color:
                        selected ? Colors.white : AppColors.onSurfaceVariant),
                selected: selected,
                onSelected: (v) => setState(
                    () => v ? _tags.add(opt.$2) : _tags.remove(opt.$2)),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.onSurface,
                    fontSize: 12),
                backgroundColor: AppColors.surfaceContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Leave a detailed review (optional)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14))),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: const [
            Icon(Icons.volunteer_activism, color: AppColors.secondaryContainer),
            SizedBox(width: 6),
            Text('Tip Kasun — 100% goes to provider',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              _TipChip(
                  label: '+LKR 200',
                  sub: 'Small Tea',
                  selected: _tipLabel == '200',
                  onTap: () => setState(() => _tipLabel = '200')),
              const SizedBox(width: 8),
              _TipChip(
                  label: '+LKR 500',
                  sub: 'Generous',
                  selected: _tipLabel == '500',
                  onTap: () => setState(() => _tipLabel = '500')),
              const SizedBox(width: 8),
              _TipChip(
                  label: 'Custom',
                  sub: 'Enter amount',
                  selected: _tipLabel == 'custom',
                  onTap: () => setState(() => _tipLabel = 'custom')),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Done',
            trailingIcon: Icons.arrow_forward,
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
              (route) => false,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.support_agent, size: 16),
              label: const Text('Need help with this order?'),
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
        Text(label,
            style: style.copyWith(
                color:
                    bold ? AppColors.onSurface : AppColors.onSurfaceVariant)),
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
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surfaceLowest,
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.surfaceHighest),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected ? AppColors.primary : AppColors.onSurface)),
            Text(sub,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
