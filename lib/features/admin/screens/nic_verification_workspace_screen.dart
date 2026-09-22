import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/admin_mock_data.dart';

class NicVerificationWorkspaceScreen extends StatefulWidget {
  const NicVerificationWorkspaceScreen({super.key});

  @override
  State<NicVerificationWorkspaceScreen> createState() => _NicVerificationWorkspaceScreenState();
}

class _NicVerificationWorkspaceScreenState extends State<NicVerificationWorkspaceScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final selectedItem = AdminMockData.verificationQueue[_selected];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Technician Identity Verification Desk',
            style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Review National Identity Cards (NIC) and police records before activating artisan profiles on the island-wide HelaService network.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'e-DLS & SL Police Link Online',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              Text(
                'Avg Turnaround: 4.2 mins',
                style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 18),

          if (isMobile)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: const [
                _QueueStat(label: 'Pending Review', value: '7', color: AppColors.secondaryContainer),
                _QueueStat(label: 'Approved', value: '1,420', color: AppColors.primary),
                _QueueStat(label: 'Needs Resubmission', value: '14', color: AppColors.outline),
                _QueueStat(label: 'Flagged / Rejected', value: '8', color: AppColors.error),
              ],
            )
          else
            const Row(
              children: [
                Expanded(child: _QueueStat(label: 'Pending Review', value: '7', color: AppColors.secondaryContainer)),
                SizedBox(width: 12),
                Expanded(child: _QueueStat(label: 'Approved', value: '1,420', color: AppColors.primary)),
                SizedBox(width: 12),
                Expanded(child: _QueueStat(label: 'Needs Resubmission', value: '14', color: AppColors.outline)),
                SizedBox(width: 12),
                Expanded(child: _QueueStat(label: 'Flagged / Rejected', value: '8', color: AppColors.error)),
              ],
            ),
          SizedBox(height: isMobile ? 16 : 20),

          if (isMobile) ...[
            // Mobile Queue Selector
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Incoming Verification Stream',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Text('${AdminMockData.verificationQueue.length} Pending', style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Text('Select an artisan to audit documents', style: TextStyle(fontSize: 10.5, color: AppColors.outline)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AdminMockData.verificationQueue.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final item = AdminMockData.verificationQueue[i];
                        final selected = i == _selected;
                        return InkWell(
                          onTap: () => setState(() => _selected = i),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 240,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surfaceLow,
                              border: Border.all(
                                color: selected ? AppColors.primary : Colors.transparent,
                                width: selected ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(children: [
                                  Icon(item.tradeIcon, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ),
                                  Text(item.timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
                                ]),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.trade} • ${item.location}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.nicNumber,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 10, color: AppColors.outline),
                                      ),
                                    ),
                                    if (item.flagged)
                                      const Text('Review Required', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700))
                                    else
                                      Text('${item.matchPercent}% Match', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailCard(selectedItem, isMobile),
          ] else ...[
            // Desktop 2-column workspace
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 340,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Incoming Verification Stream', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Text('Sorted by Urgency', style: TextStyle(fontSize: 10, color: AppColors.outline)),
                          const SizedBox(height: 10),
                          ...List.generate(AdminMockData.verificationQueue.length, (i) {
                            final item = AdminMockData.verificationQueue[i];
                            final selected = i == _selected;
                            return InkWell(
                              onTap: () => setState(() => _selected = i),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surfaceLow,
                                  border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(item.tradeIcon, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
                                      Text(item.timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
                                    ]),
                                    Text('${item.trade} • ${item.location}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                                    Text('${item.nicNumber} — ${item.docNote}', style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
                                    const SizedBox(height: 4),
                                    if (item.flagged)
                                      const Text('Review Required', style: TextStyle(fontSize: 10.5, color: AppColors.error, fontWeight: FontWeight.w700))
                                    else
                                      Text('${item.matchPercent}% Match', style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDetailCard(selectedItem, isMobile)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(dynamic selectedItem, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                selectedItem.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 15),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('NVQ Level 3 Certified', style: TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 6, children: const [
            _InfoRow(icon: Icons.call, text: '+94 77 482 1902'),
            _InfoRow(icon: Icons.home, text: 'No. 42/3, Galle Road, Colombo 06'),
            _InfoRow(icon: Icons.translate, text: 'Sinhala, English'),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(10)),
            child: Row(children: const [
              Icon(Icons.verified_user, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SL Police Clearance Portal — Ref: #SLP-2024-09881 • Verified Clean',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: const [
            Icon(Icons.document_scanner, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'OCR Audit — All 4 Fields Concordant',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if (isMobile)
            Column(
              children: AdminMockData.dilshanOcr.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(f.icon, size: 13, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.field, style: const TextStyle(fontSize: 10, color: AppColors.outline, fontWeight: FontWeight.w600)),
                          Text(f.extracted, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('Registry: ${f.registry}', style: const TextStyle(fontSize: 9.5, color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(f.status, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              )).toList(),
            )
          else
            Table(
              columnWidths: const {0: FlexColumnWidth(1.4), 1: FlexColumnWidth(2), 2: FlexColumnWidth(2), 3: FlexColumnWidth(0.8)},
              children: [
                const TableRow(children: [
                  _TCell('Data Field', header: true),
                  _TCell('OCR Extracted', header: true),
                  _TCell('Registry', header: true),
                  _TCell('Status', header: true),
                ]),
                ...AdminMockData.dilshanOcr.map((f) => TableRow(children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(f.icon, size: 13, color: AppColors.onSurfaceVariant), const SizedBox(width: 4), Flexible(child: Text(f.field, style: const TextStyle(fontSize: 11)))])),
                      _TCell(f.extracted),
                      _TCell(f.registry),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          const Icon(Icons.check, size: 13, color: AppColors.primary),
                          Text(f.status, style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                        ]),
                      ),
                    ])),
              ],
            ),
          const SizedBox(height: 16),
          Row(children: const [
            _DocPreview(icon: Icons.badge, label: 'NIC Front', tag: 'UV PASS'),
            SizedBox(width: 8),
            _DocPreview(icon: Icons.qr_code_scanner, label: 'NIC Back', tag: 'PDF417 OK'),
            SizedBox(width: 8),
            _DocPreview(icon: Icons.face, label: 'Liveness', tag: '98.4% Match'),
          ]),
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Approve & Activate Artisan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.cancel, size: 14, color: AppColors.error),
                        label: const Text('Reject', style: TextStyle(color: AppColors.error, fontSize: 11)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.replay, size: 14),
                        label: const Text('Clearer Photo', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cancel, size: 14, color: AppColors.error),
                  label: const Text('Reject', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.replay, size: 14), label: const Text('Request Clearer Photo')),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Approve & Activate Artisan'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

class _QueueStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _QueueStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppColors.onSurfaceVariant),
      const SizedBox(width: 4),
      Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
    ]);
  }
}

class _TCell extends StatelessWidget {
  final String text;
  final bool header;
  const _TCell(this.text, {this.header = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: header ? 10.5 : 11,
          color: header ? AppColors.outline : AppColors.onSurface,
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _DocPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tag;
  const _DocPreview({required this.icon, required this.label, required this.tag});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          Text(tag, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
