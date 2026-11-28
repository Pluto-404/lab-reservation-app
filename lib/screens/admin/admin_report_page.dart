import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_theme.dart';
import '../../models/laboratory_model.dart';
import '../../models/reservation_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/date_id.dart';
import '../../utils/report_calculator.dart';
import '../../widgets/info_state.dart';
import '../../widgets/reservation_status_chip.dart';
import '../../widgets/summary_stat_card.dart';

/// Halaman Laporan & Riwayat Penggunaan Laboratorium untuk Admin.
class AdminReportPage extends StatefulWidget {
  const AdminReportPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<LaboratoryModel>> _labsStream;
  late final Stream<List<ReservationModel>> _reservationsStream;

  ReportPeriod _period = ReportPeriod.all;
  String? _selectedLabId;
  String _statusFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _labsStream = _firestoreService.getAllLaboratories();
    _reservationsStream = _firestoreService.getAllReservations();
  }

  Future<void> _copySummary({
    required ReportSummary summary,
    required List<LaboratoryModel> labs,
  }) async {
    String? labName;
    if (_selectedLabId != null) {
      final matched = labs.where((l) => l.labId == _selectedLabId);
      if (matched.isNotEmpty) labName = matched.first.name;
    }

    final text = ReportCalculator.buildPlainTextSummary(
      summary: summary,
      period: _period,
      labName: labName,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ringkasan laporan disalin ke clipboard.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = StreamBuilder<List<LaboratoryModel>>(
      stream: _labsStream,
      builder: (context, labSnapshot) {
        if (labSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (labSnapshot.hasError) {
          return InfoState(
            icon: Icons.error_outline,
            text: 'Gagal memuat data laboratorium.',
            subtext: '${labSnapshot.error}',
          );
        }

        final labs = labSnapshot.data ?? [];

        return StreamBuilder<List<ReservationModel>>(
          stream: _reservationsStream,
          builder: (context, resSnapshot) {
            if (resSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (resSnapshot.hasError) {
              return InfoState(
                icon: Icons.error_outline,
                text: 'Gagal memuat data reservasi.',
                subtext: '${resSnapshot.error}',
              );
            }

            final allReservations = resSnapshot.data ?? [];
            final periodAndLabFiltered = ReportCalculator.filterReservations(
              reservations: allReservations,
              period: _period,
              labId: _selectedLabId,
            );
            final summary = ReportCalculator.summarize(
              reservations: periodAndLabFiltered,
              laboratories: _selectedLabId == null
                  ? labs
                  : labs.where((l) => l.labId == _selectedLabId).toList(),
            );
            final visibleHistory = ReportCalculator.filterReservations(
              reservations: allReservations,
              period: _period,
              labId: _selectedLabId,
              statusFilter: _statusFilter,
            );

            final maxLabMinutes = summary.labStats.isEmpty
                ? 0
                : summary.labStats
                    .map((s) => s.totalMinutes)
                    .reduce((a, b) => a > b ? a : b);

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laporan & Riwayat Penggunaan',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Evaluasi utilisasi laboratorium dan riwayat peminjaman kampus.',
                            style: TextStyle(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _copySummary(summary: summary, labs: labs),
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text('Salin Rekap'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Periode & Laboratorium
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ReportPeriod.values.map((p) {
                    return ChoiceChip(
                      label: Text(p.label),
                      selected: _period == p,
                      onSelected: (_) => setState(() => _period = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedLabId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.apartment_outlined),
                    labelText: 'Filter Laboratorium',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Semua Laboratorium'),
                    ),
                    ...labs.map(
                      (lab) => DropdownMenuItem<String?>(
                        value: lab.labId,
                        child: Text(lab.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedLabId = value),
                ),
                const SizedBox(height: 24),

                // Ringkasan Metrik
                LayoutBuilder(
                  builder: (context, box) {
                    final columns = box.maxWidth >= 700
                        ? 4
                        : box.maxWidth >= 450
                            ? 2
                            : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: columns >= 4
                          ? 1.9
                          : columns == 2
                              ? 2.5
                              : 3.8,
                      children: [
                        SummaryStatCard(
                          title: 'Total Peminjaman',
                          value: '${summary.totalBookings}',
                          icon: Icons.receipt_long_outlined,
                          iconColor: AppTheme.primary,
                          backgroundColor: AppTheme.soft,
                        ),
                        SummaryStatCard(
                          title: 'Total Jam Pakai',
                          value: ReportCalculator.formatHours(
                            summary.totalUsageHours,
                          ),
                          icon: Icons.schedule_outlined,
                          iconColor: AppTheme.deep,
                          backgroundColor: AppTheme.soft,
                        ),
                        SummaryStatCard(
                          title: 'Tingkat Disetujui',
                          value: '${summary.approvalRatePercent}%',
                          icon: Icons.verified_outlined,
                          iconColor: AppTheme.success,
                          backgroundColor: AppTheme.successSoft,
                        ),
                        SummaryStatCard(
                          title: 'Peminjaman Walk-in',
                          value: '${summary.walkInCount}',
                          icon: Icons.meeting_room_outlined,
                          iconColor: AppTheme.warning,
                          backgroundColor: AppTheme.warningSoft,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),
                const Text(
                  'Utilisasi per Laboratorium',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),

                if (summary.labStats.isEmpty)
                  const InfoState(
                    icon: Icons.bar_chart_outlined,
                    text: 'Belum ada data laboratorium.',
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          for (int i = 0; i < summary.labStats.length; i++) ...[
                            _LabUtilizationRow(
                              stat: summary.labStats[i],
                              maxMinutes: maxLabMinutes,
                            ),
                            if (i < summary.labStats.length - 1)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: AppTheme.outline,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Riwayat Peminjaman',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      '${visibleHistory.length} entri',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    ('Semua', 'semua'),
                    ('Disetujui', 'approved'),
                    ('Selesai', 'completed'),
                    ('Menunggu', 'pending'),
                    ('Ditolak', 'rejected'),
                    ('Dibatalkan', 'cancelled'),
                  ].map((item) {
                    return ChoiceChip(
                      label: Text(item.$1),
                      selected: _statusFilter == item.$2,
                      onSelected: (_) =>
                          setState(() => _statusFilter = item.$2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                if (visibleHistory.isEmpty)
                  const InfoState(
                    icon: Icons.history_outlined,
                    text: 'Tidak ada riwayat peminjaman pada filter ini.',
                    subtext: 'Ubah filter periode, lab, atau status.',
                  )
                else
                  ...visibleHistory.map((item) {
                    final status = ReportCalculator.effectiveStatus(item);
                    final isWalkIn = item.type == 'walk_in';
                    final identityParts = <String>[
                      if (item.studentNim.isNotEmpty && item.studentNim != '-')
                        'NIM: ${item.studentNim}',
                      if (item.studentClass.isNotEmpty &&
                          item.studentClass != '-')
                        item.studentClass,
                      if (isWalkIn) 'Walk-in',
                    ];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.soft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isWalkIn
                                      ? Icons.meeting_room_outlined
                                      : Icons.person_outline,
                                  color: AppTheme.deep,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.studentName.isEmpty
                                                ? 'Tanpa Nama'
                                                : item.studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppTheme.ink,
                                            ),
                                          ),
                                        ),
                                        ReservationStatusChip(
                                          status: status,
                                          compact: true,
                                        ),
                                      ],
                                    ),
                                    if (identityParts.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        identityParts.join(' • '),
                                        style: const TextStyle(
                                          color: AppTheme.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 5),
                                    Text(
                                      '${item.labName} • ${DateId.short(item.startTime)} '
                                      '(${DateId.range(item.startTime, item.endTime)})',
                                      style: const TextStyle(
                                        color: AppTheme.deep,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (item.purpose.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.purpose,
                                        style: const TextStyle(
                                          color: AppTheme.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );

    if (!widget.showAppBar) {
      return PageWidth(maxWidth: 850, child: bodyContent);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan & Utilisasi')),
      body: PageWidth(maxWidth: 850, child: bodyContent),
    );
  }
}

class _LabUtilizationRow extends StatelessWidget {
  const _LabUtilizationRow({
    required this.stat,
    required this.maxMinutes,
  });

  final LabUtilizationStat stat;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final progress = maxMinutes <= 0 ? 0.0 : stat.totalMinutes / maxMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                stat.labName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.ink,
                ),
              ),
            ),
            Text(
              '${stat.bookingCount} peminjaman • '
              '${ReportCalculator.formatHours(stat.totalHours)}',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.soft,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ],
    );
  }
}
