import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;
import '../../../constants/firestore_paths.dart';
import '../../../theme/app_theme.dart';
import '../../../models/job_request.dart';
import '../../../models/quote.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../shared/widgets/photo_placeholder.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../state/role_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';

class SubmitQuoteSheet extends StatefulWidget {
  final JobRequest jobRequest;

  const SubmitQuoteSheet({super.key, required this.jobRequest});

  @override
  State<SubmitQuoteSheet> createState() => _SubmitQuoteSheetState();
}

class _SubmitQuoteSheetState extends State<SubmitQuoteSheet> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  int _selectedEta = 30;
  bool _submitting = false;

  static const List<int> _etaOptions = [15, 30, 45, 60, 90, 120];

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _etaLabel(int mins) {
    if (mins < 60) return '$mins min';
    if (mins == 60) return '1 hr';
    if (mins == 90) return '1.5 hr';
    if (mins == 120) return '2 hr';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  Future<void> _submit() async {
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterQuotedPriceError)),
      );
      return;
    }
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
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

      double providerRating = 5.0;
      int providerReviews = 0;
      try {
        final techDoc = await FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(user.uid)
            .get();
        if (techDoc.exists) {
          final tData = techDoc.data();
          if (tData != null) {
            providerRating = (tData['rating'] as num?)?.toDouble() ?? 5.0;
            providerReviews = (tData['reviewCount'] as num?)?.toInt() ?? 0;
          }
        }
      } catch (_) {}

      final quote = Quote(
        requestId: widget.jobRequest.id,
        providerId: user.uid,
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        providerName: profile?.displayName.isNotEmpty == true ? profile!.displayName : 'Service Provider',
        providerRating: providerRating,
        providerReviewCount: providerReviews,
        providerNicVerified: profile?.nic?.isNotEmpty == true,
        providerTrade: profile?.serviceCategory ?? '',
        providerPhone: profile?.phone ?? '',
        providerLatitude: profile?.latitude,
        providerLongitude: profile?.longitude,
        quotedPrice: price,
        etaMinutes: _selectedEta,
        notes: _notesController.text.trim(),
      );

      await JobRequestRepository()
          .submitQuote(widget.jobRequest.id, quote);

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
            content: Text('Failed to submit quote: $e'),
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
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
                                LocalizedData.getCategory(context, req.category),
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
                    if (req.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.customerPhotos,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: req.photoUrls.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final url = req.photoUrls[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _buildPhoto(url, 72, 72),
                            );
                          },
                        ),
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

              const SizedBox(height: 20),

              Text(
                context.l10n.yourQuotedPrice,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  hintText: '3,500',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextSecondary.withValues(alpha: 0.4),
                  ),
                  prefixText: 'LKR ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextSecondary,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
              ),

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
                        _etaLabel(mins),
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
                  hintText:
                      'e.g. Price includes inspection and basic parts...',
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
                label: context.l10n.sendPriceQuote,
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

  Widget _buildPhoto(String url, double width, double height) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(Uint8List.fromList(bytes),
            width: width, height: height, fit: BoxFit.cover);
      } catch (_) {
        return PhotoPlaceholder(width: width, height: height);
      }
    }
    return Image.network(url,
        width: width, height: height, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            PhotoPlaceholder(width: width, height: height));
  }
}
