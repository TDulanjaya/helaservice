import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/admin_mock_data.dart';
import '../../../data/models/admin_models.dart';

class CategoryDistrictManagementScreen extends StatelessWidget {
  const CategoryDistrictManagementScreen({super.key});

  void _openAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Service Category'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Define default tariff caps and operational bounds.', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              SizedBox(height: 14),
              TextField(decoration: InputDecoration(labelText: 'Trade Title (English / Sinhala / Tamil)')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Base Inspection (LKR)'), keyboardType: TextInputType.number),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Hourly Labor Cap (LKR)'), keyboardType: TextInputType.number),
              SizedBox(height: 10),
              Text('Initial Districts Scope', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Wrap(spacing: 6, children: [
                Chip(label: Text('Colombo')),
                Chip(label: Text('Gampaha')),
                Chip(label: Text('Kandy')),
                Chip(label: Text('Galle')),
              ]),
              SizedBox(height: 6),
              CheckboxListTile(
                value: true,
                onChanged: null,
                contentPadding: EdgeInsets.zero,
                title: Text('Enable LankaQR Dynamic Tariffs', style: TextStyle(fontSize: 13)),
                subtitle: Text('Enforce Central Bank LankaQR standard checkout', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save & Publish Category'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Service Categories & District Coverage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Manage home service pricing, surge thresholds, and active technician coverage across Sri Lankan districts.',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download, size: 14), label: const Text('Export Tariff Matrix')),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _openAddCategoryDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add New Category'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ]),
          const SizedBox(height: 20),
          const Row(children: [
            _MiniCard(icon: Icons.category, value: '14 Services', label: 'Catalog Density', sub: '8 Active — provincial districts covered with SLSI compliance'),
            SizedBox(width: 12),
            _MiniCard(icon: Icons.engineering, value: '1,892 Vetted Pros', label: 'Active Artisan Fleet', sub: '98.2% fulfillment SLA — 412 Live on Map'),
            SizedBox(width: 12),
            _MiniCard(icon: Icons.bolt, value: '1.2x Peak', label: 'Real-Time Tariff Dynamic', sub: 'Triggered in Colombo 03, 04, 07 (Rainfall surge)'),
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                ...AdminMockData.categories.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(10)),
                            child: Icon(c.icon, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 220,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                Text(c.description, style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
                                Text('${c.registered} • ${c.onlineNow}', style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.baseFee, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                Text(c.hourlyCap, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                ...c.districts.map((d) => _DistrictTag(label: d)),
                                ...c.districtsOff.map((d) => _DistrictTag(label: '$d [OFF]', muted: true)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(c.surge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          SizedBox(
                            width: 80,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (c.status == 'Active' ? AppColors.primary : AppColors.secondaryContainer).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(c.status,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.status == 'Active' ? AppColors.primary : AppColors.onSecondaryContainer)),
                            ),
                          ),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, size: 16), color: AppColors.onSurfaceVariant),
                        ],
                      ),
                    )),
                const Text('Showing 6 of 14 categories registered in Western & Central Provinces', style: TextStyle(fontSize: 10.5, color: AppColors.outline)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('District Expansion & Waitlist Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Text('Prospective artisan intake & customer demand telemetry across pipeline provinces.', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(children: AdminMockData.expansionDistricts.map((d) => Expanded(child: _ExpansionCard(d: d))).toList()),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sub;
  const _MiniCard({required this.icon, required this.value, required this.label, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 15, color: AppColors.primary), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant))]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _DistrictTag extends StatelessWidget {
  final String label;
  final bool muted;
  const _DistrictTag({required this.label, this.muted = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: muted ? AppColors.surfaceLow : AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 9.5, color: muted ? AppColors.outline : AppColors.onSurface)),
    );
  }
}

class _ExpansionCard extends StatelessWidget {
  final ExpansionDistrict d;
  const _ExpansionCard({required this.d});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(d.hubName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
            Text('${(d.readiness * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ]),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: d.readiness, minHeight: 5, backgroundColor: AppColors.surfaceHigh, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text(d.location, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(d.description, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Signups: ${d.signups}', style: const TextStyle(fontSize: 10)),
          Text('Pre-registrations: ${d.preregistrations}', style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(d.ctaIcon, size: 13),
              label: Text(d.ctaLabel, style: const TextStyle(fontSize: 10.5)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
            ),
          ),
        ],
      ),
    );
  }
}
