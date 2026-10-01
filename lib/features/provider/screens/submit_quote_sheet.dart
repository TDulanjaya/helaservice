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

              Text(context.l10n.submitPriceQuote,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(context.l10n.submitPriceQuoteSub,
                  style: TextStyle(
                      fontSize: 12.5, color: context.themeTextSecondary)),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              LocalizedData.getCategory(context, req.category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.person_outline,
                            size: 14, color: context.themeTextSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            req.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color: context.themeTextSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(req.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(req.description,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: context.themeTextSecondary)),
                    if (req.address.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 13, color: context.themeTextSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(req.address,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.themeTextSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (req.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(context.l10n.customerPhotos,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: req.photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final url = req.photoUrls[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildPhoto(url, 120, 120),
                      );
                    },
                  ),
                ),
              ],

              if (req.latitude != null && req.longitude != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.near_me,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'GPS: ${req.latitude!.toStringAsFixed(4)}, ${req.longitude!.toStringAsFixed(4)}',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: context.themeTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              Text(context.l10n.yourQuotedPrice,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  hintText: 'e.g. 2500',
                  hintStyle: TextStyle(
                      fontSize: 18,
                      color: context.themeTextSecondary.withValues(alpha: 0.5)),
                  prefixText: 'LKR ',
                  prefixStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextSecondary),
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),

              const SizedBox(height: 16),
              Text(context.l10n.estimatedArrivalTime,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _etaOptions.map((mins) {
                  final selected = _selectedEta == mins;
                  return ChoiceChip(
                    label: Text(_etaLabel(mins)),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedEta = mins),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: context.themeSurfaceLow,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : context.themeBorder,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : context.themeTextSecondary,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              Text(context.l10n.messageToCustomerOptional,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'e.g. Price includes full inspection and basic parts...',
                  hintStyle: TextStyle(
                      fontSize: 12, color: context.themeTextSecondary),
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send, size: 18),
                          const SizedBox(width: 8),
                          Text(context.l10n.sendPriceQuote,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
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
