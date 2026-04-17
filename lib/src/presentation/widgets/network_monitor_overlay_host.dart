import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network_monitor_facade.dart';
import '../../domain/entities/network_log_entry.dart';
import '../../domain/usecases/clear_network_logs_usecase.dart';
import '../../domain/usecases/get_network_logs_stream_usecase.dart';
import '../bloc/network_monitor_bloc.dart';

class NetworkMonitorOverlayHost extends StatelessWidget {
  const NetworkMonitorOverlayHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return child;
    }

    final repository = NetworkMonitorFacade.instance.repository;
    NetworkMonitorFacade.instance.ensureCaptureStarted();

    return BlocProvider<NetworkMonitorBloc>(
      create: (_) => NetworkMonitorBloc(
        getLogsStream: GetNetworkLogsStreamUseCase(repository),
        clearLogs: ClearNetworkLogsUseCase(repository),
        initialVisible: false,
      ),
      child: _NetworkMonitorOverlayView(child: child),
    );
  }
}

class _NetworkMonitorOverlayView extends StatelessWidget {
  const _NetworkMonitorOverlayView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const _MonitorControlChip(),
        const _MonitorBottomSheet(),
      ],
    );
  }
}

class _MonitorControlChip extends StatefulWidget {
  const _MonitorControlChip();

  @override
  State<_MonitorControlChip> createState() => _MonitorControlChipState();
}

class _MonitorControlChipState extends State<_MonitorControlChip> {
  static const double _chipWidth = 136;
  static const double _chipHeight = 44;
  Offset? _position;
  bool _isDragging = false;

  Offset _clampPosition({
    required Offset value,
    required Size screenSize,
    required EdgeInsets padding,
  }) {
    final minX = 8.0;
    final rawMaxX = screenSize.width - _chipWidth - 8;
    final maxX = rawMaxX < minX ? minX : rawMaxX;
    final minY = padding.top + 6;
    final rawMaxY = screenSize.height - _chipHeight - padding.bottom - 6;
    final maxY = rawMaxY < minY ? minY : rawMaxY;

    return Offset(
      value.dx.clamp(minX, maxX),
      value.dy.clamp(minY, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final padding = media.padding;
    _position ??= Offset(size.width - _chipWidth - 12, padding.top + 10);
    _position = _clampPosition(
      value: _position!,
      screenSize: size,
      padding: padding,
    );

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _isDragging = false;
        },
        onPanUpdate: (details) {
          setState(() {
            _isDragging = true;
            _position = _clampPosition(
              value: _position! + details.delta,
              screenSize: size,
              padding: padding,
            );
          });
        },
        onPanEnd: (_) {
          Future<void>.delayed(const Duration(milliseconds: 70), () {
            if (mounted) {
              _isDragging = false;
            }
          });
        },
        child: BlocBuilder<NetworkMonitorBloc, NetworkMonitorState>(
          buildWhen: (prev, curr) =>
              prev.enabled != curr.enabled ||
              prev.logs.length != curr.logs.length,
          builder: (context, state) {
            final enabled = state.enabled;
            final theme = Theme.of(context);
            final gradient = enabled
                ? const <Color>[Color(0xFF0F766E), Color(0xFF0369A1)]
                : const <Color>[Color(0xFF334155), Color(0xFF1E293B)];

            return AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: enabled
                        ? const Color(0xFF14B8A6).withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.24),
                    blurRadius: enabled ? 22 : 12,
                    spreadRadius: enabled ? 1.5 : 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(32),
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () {
                    if (_isDragging) return;
                    context.read<NetworkMonitorBloc>().add(
                          NetworkMonitorEnableChanged(!enabled),
                        );
                  },
                  child: Ink(
                    width: _chipWidth,
                    height: _chipHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.34),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                enabled
                                    ? Icons.wifi_tethering_rounded
                                    : Icons.wifi_off_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              if (enabled)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF86EFAC),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Net ${state.logs.length}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 42,
                          height: 24,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: enabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                enabled
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 11,
                                color: enabled
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MonitorBottomSheet extends StatefulWidget {
  const _MonitorBottomSheet();

  @override
  State<_MonitorBottomSheet> createState() => _MonitorBottomSheetState();
}

class _MonitorBottomSheetState extends State<_MonitorBottomSheet> {
  double _heightFactor = 0.42;

  void _onDragResize(DragUpdateDetails details) {
    final height = MediaQuery.of(context).size.height;
    setState(() {
      _heightFactor =
          (_heightFactor - (details.delta.dy / height)).clamp(0.30, 0.90);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: BlocBuilder<NetworkMonitorBloc, NetworkMonitorState>(
        builder: (context, state) {
          final sheetHeight =
              MediaQuery.of(context).size.height * _heightFactor;
          final successCount =
              state.logs.where((log) => (log.statusCode ?? 0) < 400).length;
          final failedCount =
              state.logs.where((log) => (log.statusCode ?? 0) >= 400).length;
          return AnimatedSlide(
            offset: state.enabled ? Offset.zero : const Offset(0, 1.2),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !state.enabled,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Stack(
                  children: [
                    Material(
                      elevation: 14,
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        height: sheetHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xF0192539),
                              Color(0xE6121A2A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -40,
                              top: -34,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF06B6D4,
                                  ).withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            Positioned(
                              left: -30,
                              bottom: -48,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF22C55E,
                                  ).withValues(alpha: 0.10),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                const SizedBox(height: 8),
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onVerticalDragUpdate: _onDragResize,
                                  child: Container(
                                    width: 44,
                                    height: 18,
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 44,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white38,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(14, 12, 10, 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0EA5E9),
                                              Color(0xFF14B8A6),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.monitor_heart_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Network Console',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            Text(
                                              'Live requests from current session',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Colors.white70,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FilledButton.tonalIcon(
                                        style: FilledButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          foregroundColor: Colors.white,
                                          backgroundColor:
                                              Colors.white.withValues(
                                            alpha: 0.16,
                                          ),
                                        ),
                                        onPressed: () {
                                          context
                                              .read<NetworkMonitorBloc>()
                                              .add(
                                                const NetworkMonitorClearPressed(),
                                              );
                                        },
                                        icon: const Icon(
                                          Icons.delete_sweep_rounded,
                                        ),
                                        label: const Text('Clear'),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Row(
                                    children: [
                                      _CountBadge(
                                        count: state.logs.length,
                                        color: const Color(0xFF38BDF8),
                                        label: 'Total',
                                      ),
                                      const SizedBox(width: 8),
                                      _CountBadge(
                                        count: successCount,
                                        color: const Color(0xFF4ADE80),
                                        label: 'OK',
                                      ),
                                      const SizedBox(width: 8),
                                      _CountBadge(
                                        count: failedCount,
                                        color: const Color(0xFFFB7185),
                                        label: 'Err',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1, color: Colors.white24),
                                Expanded(
                                  child: state.logs.isEmpty
                                      ? const _EmptyLogsView()
                                      : ListView.separated(
                                          padding: const EdgeInsets.all(10),
                                          itemCount: state.logs.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final entry = state.logs[index];
                                            return _LogTile(entry: entry);
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.selectedLog != null)
                      Positioned.fill(
                        child:
                            _InlineDetailBottomSheet(entry: state.selectedLog!),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.color,
    required this.label,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.46)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLogsView extends StatelessWidget {
  const _EmptyLogsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.analytics_outlined, color: Colors.white70, size: 30),
            SizedBox(height: 10),
            Text(
              'No API logs yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Send requests and inspect their payloads live here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final NetworkLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final status = entry.statusCode ?? 0;
    final statusColor = status >= 500
        ? Colors.redAccent
        : status >= 400
            ? Colors.orangeAccent
            : const Color(0xFF4ADE80);

    final subtitle = '${entry.statusCode ?? '-'} • ${entry.durationMs ?? 0}ms';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.read<NetworkMonitorBloc>().add(
                NetworkMonitorDetailRequested(entry),
              );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.40),
                      ),
                    ),
                    child: Text(
                      entry.method,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogDetailSheet extends StatelessWidget {
  const _LogDetailSheet({
    required this.entry,
    this.onTopDragUpdate,
  });

  final NetworkLogEntry entry;
  final ValueChanged<DragUpdateDetails>? onTopDragUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF111827),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: onTopDragUpdate,
            child: Container(
              width: 64,
              height: 16,
              alignment: Alignment.center,
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF14B8A6)],
                    ),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: const Icon(
                    Icons.data_object_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${entry.method} ${entry.statusCode ?? '-'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () {
                    context.read<NetworkMonitorBloc>().add(
                          const NetworkMonitorDetailClosed(),
                        );
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _PayloadBlock(title: 'Meta', value: _buildMeta(entry)),
                _PayloadBlock(
                  title: 'Request Headers',
                  value: entry.requestHeaders ??
                      'Not available in package-only mode',
                ),
                _PayloadBlock(
                  title: 'Request Body',
                  value: entry.requestBody ?? 'No request body',
                ),
                _PayloadBlock(
                  title: 'Response Headers',
                  value: entry.responseHeaders ??
                      'Not available in package-only mode',
                ),
                _PayloadBlock(
                  title: 'Response Body',
                  value: entry.responseBody ?? 'No response body',
                ),
                if (entry.rawRequest != null && entry.rawRequest!.isNotEmpty)
                  _PayloadBlock(
                    title: 'Raw Request Block',
                    value: entry.rawRequest!,
                  ),
                if (entry.rawResponse != null && entry.rawResponse!.isNotEmpty)
                  _PayloadBlock(
                    title: 'Raw Response Block',
                    value: entry.rawResponse!,
                  ),
                if (entry.error != null)
                  _PayloadBlock(title: 'Error', value: entry.error!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineDetailBottomSheet extends StatefulWidget {
  const _InlineDetailBottomSheet({required this.entry});

  final NetworkLogEntry entry;

  @override
  State<_InlineDetailBottomSheet> createState() =>
      _InlineDetailBottomSheetState();
}

class _InlineDetailBottomSheetState extends State<_InlineDetailBottomSheet> {
  double _heightFactor = 0.74;

  void _onDragResize(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    setState(() {
      _heightFactor =
          (_heightFactor - (details.delta.dy / screenHeight)).clamp(0.48, 0.97);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                context.read<NetworkMonitorBloc>().add(
                      const NetworkMonitorDetailClosed(),
                    );
              },
              child: const SizedBox.expand(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              height: MediaQuery.of(context).size.height * _heightFactor,
              child: _LogDetailSheet(
                entry: widget.entry,
                onTopDragUpdate: _onDragResize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _buildMeta(NetworkLogEntry entry) {
  final ts = entry.timestamp.toIso8601String();
  return 'Method: ${entry.method}\n'
      'Status: ${entry.statusCode ?? '-'}\n'
      'Duration: ${entry.durationMs ?? 0} ms\n'
      'Timestamp: $ts\n'
      'Type: ${entry.isMultipart ? 'Multipart' : 'JSON/HTTP'}';
}

class _PayloadBlock extends StatelessWidget {
  const _PayloadBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cleanedValue = _cleanPayloadValue(value);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: cleanedValue),
                  );
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  messenger?.hideCurrentSnackBar();
                  messenger?.showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 800),
                      content: Text('$title copied'),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.content_copy_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ],
          ),
          SelectableText(
            cleanedValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

String _cleanPayloadValue(String input) {
  final lines = input.split('\n');
  final cleaned = <String>[];

  for (final line in lines) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) {
      continue;
    }
    if (RegExp(r'^[\s╔╚╠═\-\|]+$').hasMatch(trimmed)) {
      continue;
    }
    final normalized = trimmed.replaceFirst(RegExp(r'^[\s║\|]+'), '');
    if (normalized.trim().isNotEmpty) {
      cleaned.add(normalized);
    }
  }

  if (cleaned.isEmpty) {
    return input.trim();
  }
  return cleaned.join('\n');
}
