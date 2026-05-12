import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shield/flutter_shield.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E1A),
  ));
  runApp(const MyApp());
}

// ── Palette ──────────────────────────────────────────────────────────────────

const _bg      = Color(0xFF0A0E1A);
const _surface = Color(0xFF111827);
const _card    = Color(0xFF1A2236);
const _border  = Color(0xFF243047);
const _accent  = Color(0xFF00D4AA);
const _danger  = Color(0xFFFF4757);
const _warn    = Color(0xFFFFB347);
const _blue    = Color(0xFF4B8EFF);
const _textPri = Color(0xFFE8EDF5);
const _textSec = Color(0xFF7A8BA8);

// ── App ───────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Shield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          secondary: _blue,
          surface: _surface,
          error: _danger,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ── Home Screen ───────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  SecurityReport? _lastReport;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _runFullScan() async {
    setState(() => _scanning = true);
    try {
      final report = await FlutterShield.performFullSecurityCheck();
      if (!mounted) return;
      setState(() {
        _lastReport = report;
        _scanning = false;
      });
      if (mounted) {
        Navigator.push(
          context,
          _slideRoute(ResultsScreen(report: report, onRescan: _runFullScan)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      _showError('Scan failed: $e');
    }
  }

  Future<void> _quickCheck(
    String label,
    Future<SecurityCheckResult> Function() check,
  ) async {
    try {
      final result = await check();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: _card,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => QuickResultSheet(label: label, result: result),
      );
    } catch (e) {
      if (mounted) _showError('Check failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.3,
                colors: [Color(0xFF0D2040), _bg],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverToBoxAdapter(child: _hero()),
                SliverToBoxAdapter(child: _scanButton()),
                SliverToBoxAdapter(child: _quickChecksSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
          if (_scanning) _scanningOverlay(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _Pill(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('v1.1.7',
                  style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          const Spacer(),
          _Pill(
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shield_outlined, color: _textSec, size: 14),
              SizedBox(width: 6),
              Text('Flutter Shield',
                  style: TextStyle(color: _textSec, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(children: [
        // Animated shield
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.1 + _pulse.value * 0.2),
                  blurRadius: 40 + _pulse.value * 30,
                  spreadRadius: _pulse.value * 12,
                ),
              ],
            ),
            child: child,
          ),
          child: Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A3A5C), Color(0xFF0D1F3C)],
              ),
              border: Border.all(color: _accent.withValues(alpha: 0.35), width: 2),
            ),
            child: const Icon(Icons.shield, size: 72, color: _accent),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Flutter Shield',
          style: TextStyle(
            fontSize: 34, fontWeight: FontWeight.w800,
            color: _textPri, letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Comprehensive device security scanner',
          style: TextStyle(fontSize: 15, color: _textSec),
        ),
        if (_lastReport != null) ...[
          const SizedBox(height: 20),
          _LastScanBadge(report: _lastReport!),
        ],
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _scanButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _scanning ? null : _runFullScan,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: _scanning
                ? null
                : const LinearGradient(colors: [_accent, Color(0xFF00A884)]),
            color: _scanning ? _card : null,
            border: _scanning ? Border.all(color: _border) : null,
            boxShadow: _scanning
                ? null
                : [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              _lastReport == null ? Icons.radar : Icons.refresh,
              color: _scanning ? _textSec : Colors.black87,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              _scanning
                  ? 'Scanning...'
                  : (_lastReport == null ? 'Start Full Security Scan' : 'Rescan Device'),
              style: TextStyle(
                color: _scanning ? _textSec : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static const _quickItems = [
    ('Root / Jailbreak',  Icons.phonelink_lock,         'root'),
    ('Debuggable App',    Icons.bug_report_outlined,    'debug'),
    ('USB Debugging',     Icons.usb,                    'usb'),
    ('Emulator',          Icons.phone_android,           'emu'),
    ('Screen Lock',       Icons.lock_outline,            'lock'),
    ('Malware Scan',      Icons.security_update_warning, 'malware'),
  ];

  Widget _quickChecksSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Quick Checks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
          const Spacer(),
          Text('${_quickItems.length} checks',
              style: const TextStyle(fontSize: 12, color: _textSec)),
        ]),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.02,
          ),
          itemCount: _quickItems.length,
          itemBuilder: (_, i) {
            final (label, icon, key) = _quickItems[i];
            return _QuickCheckCard(
              label: label,
              icon: icon,
              onTap: () => _quickCheck(label, _resolveCheck(key)),
            );
          },
        ),
      ]),
    );
  }

  Future<SecurityCheckResult> Function() _resolveCheck(String key) {
    return switch (key) {
      'root'    => FlutterShield.checkRootedJailbroken,
      'debug'   => FlutterShield.checkDebuggable,
      'usb'     => FlutterShield.checkUsbDebugging,
      'emu'     => FlutterShield.checkEmulator,
      'lock'    => FlutterShield.checkScreenLock,
      'malware' => FlutterShield.checkMalware,
      _         => FlutterShield.checkRootedJailbroken,
    };
  }

  Widget _scanningOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: const Center(child: _ScanningCard()),
    );
  }
}

// ── Results Screen ────────────────────────────────────────────────────────────

class ResultsScreen extends StatefulWidget {
  final SecurityReport report;
  final VoidCallback onRescan;
  const ResultsScreen({super.key, required this.report, required this.onRescan});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scoreCtrl;
  late final Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _scoreAnim =
        CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);
    _scoreCtrl.forward();
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    super.dispose();
  }

  int get _score {
    if (widget.report.totalChecks == 0) return 100;
    final passed = widget.report.totalChecks - widget.report.vulnerabilitiesFound;
    return ((passed / widget.report.totalChecks) * 100).round();
  }

  Color get _scoreColor {
    if (_score >= 80) return _accent;
    if (_score >= 50) return _warn;
    return _danger;
  }

  String get _scoreLabel {
    if (_score >= 80) return 'Well Protected';
    if (_score >= 60) return 'Moderate Risk';
    if (_score >= 40) return 'High Risk';
    return 'Critical Risk';
  }

  Map<String, List<SecurityCheckResult>> get _grouped {
    final map = <String, List<SecurityCheckResult>>{};
    for (final r in widget.report.results) {
      final cat = _categoryOf(r.type);
      if (!map.containsKey(cat)) map[cat] = [];
      map[cat]!.add(r);
    }
    return map;
  }

  String _categoryOf(VulnerabilityType t) {
    switch (t) {
      case VulnerabilityType.rootedJailbroken:
      case VulnerabilityType.debuggableApp:
      case VulnerabilityType.usbDebugging:
      case VulnerabilityType.emulatorDetection:
      case VulnerabilityType.malwareExposure:
        return 'Device Integrity';
      case VulnerabilityType.insecureLocalStorage:
      case VulnerabilityType.plaintextData:
      case VulnerabilityType.improperKeychainKeystore:
      case VulnerabilityType.insecureFilePermissions:
      case VulnerabilityType.externalStorageSensitiveData:
      case VulnerabilityType.backupEnabled:
        return 'Storage Security';
      case VulnerabilityType.weakBiometricHandling:
      case VulnerabilityType.biometricBypass:
      case VulnerabilityType.screenLockNotEnforced:
        return 'Authentication';
      case VulnerabilityType.screenshotNotRestricted:
      case VulnerabilityType.screenRecordingNotRestricted:
      case VulnerabilityType.clipboardLeakage:
      case VulnerabilityType.overlayAttack:
      case VulnerabilityType.backgroundDataExposure:
      case VulnerabilityType.recentAppsExposure:
        return 'UI Security';
      case VulnerabilityType.insecureIPC:
      case VulnerabilityType.intentHijacking:
      case VulnerabilityType.broadcastReceiverExposure:
      case VulnerabilityType.deepLinkHijacking:
        return 'Communication';
      case VulnerabilityType.webViewDebugging:
      case VulnerabilityType.webViewJavaScriptAbuse:
        return 'WebView';
      case VulnerabilityType.runtimePermissionMissing:
      case VulnerabilityType.insecureAutofill:
      case VulnerabilityType.sensorAbuse:
        return 'Permissions';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Tinted top gradient based on score
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_scoreColor.withValues(alpha: 0.07), Colors.transparent],
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _appBar(context),
              SliverToBoxAdapter(child: _scoreSection()),
              SliverToBoxAdapter(child: _statsRow()),
              SliverToBoxAdapter(child: _categorySections()),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
          // Floating rescan button
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: _rescanButton(context),
          ),
        ],
      ),
    );
  }

  SliverAppBar _appBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      title: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 15, color: _textPri),
          ),
        ),
        const SizedBox(width: 14),
        const Text('Security Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Text(
            _formatTime(widget.report.timestamp),
            style: const TextStyle(fontSize: 12, color: _textSec, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _scoreSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Column(children: [
        AnimatedBuilder(
          animation: _scoreAnim,
          builder: (_, __) {
            final progress = _scoreAnim.value * (_score / 100);
            final displayScore = (_scoreAnim.value * _score).round();
            return CustomPaint(
              size: const Size(190, 190),
              painter: _ScoreRingPainter(progress: progress, color: _scoreColor),
              child: SizedBox(
                width: 190, height: 190,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    '$displayScore',
                    style: TextStyle(
                      fontSize: 56, fontWeight: FontWeight.w900,
                      color: _scoreColor, height: 1,
                    ),
                  ),
                  const Text('SCORE',
                      style: TextStyle(fontSize: 11, color: _textSec,
                          letterSpacing: 2.5, fontWeight: FontWeight.w600)),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(_scoreLabel,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _scoreColor)),
        const SizedBox(height: 4),
        Text(
          '${widget.report.vulnerabilitiesFound} issue${widget.report.vulnerabilitiesFound == 1 ? '' : 's'} '
          'found across ${widget.report.totalChecks} checks',
          style: const TextStyle(fontSize: 14, color: _textSec),
        ),
      ]),
    );
  }

  Widget _statsRow() {
    final passed = widget.report.totalChecks - widget.report.vulnerabilitiesFound;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(children: [
        _StatTile(value: '$passed', label: 'Passed', color: _accent),
        const SizedBox(width: 10),
        _StatTile(value: '${widget.report.vulnerabilitiesFound}', label: 'Failed', color: _danger),
        const SizedBox(width: 10),
        _StatTile(value: '${widget.report.totalChecks}', label: 'Total', color: _blue),
      ]),
    );
  }

  Widget _categorySections() {
    final groups = _grouped.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Detailed Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
        const SizedBox(height: 14),
        ...groups.map((e) => _CategorySection(category: e.key, results: e.value)),
      ]),
    );
  }

  Widget _rescanButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onRescan();
      },
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _card,
          border: Border.all(color: _accent.withValues(alpha: 0.5), width: 1.5),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.refresh_rounded, color: _accent, size: 20),
          SizedBox(width: 8),
          Text('Rescan Device',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

class _LastScanBadge extends StatelessWidget {
  final SecurityReport report;
  const _LastScanBadge({required this.report});

  @override
  Widget build(BuildContext context) {
    final score = report.totalChecks == 0
        ? 100
        : ((report.totalChecks - report.vulnerabilitiesFound) / report.totalChecks * 100).round();
    final color = score >= 80 ? _accent : score >= 50 ? _warn : _danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Text('Last scan: $score / 100',
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: _textSec, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _QuickCheckCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickCheckCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _blue, size: 22),
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: _textSec, fontWeight: FontWeight.w500),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final String category;
  final List<SecurityCheckResult> results;
  const _CategorySection({required this.category, required this.results});

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  int get _vulnCount => widget.results.where((r) => r.isVulnerable).length;

  IconData _categoryIcon() {
    return switch (widget.category) {
      'Device Integrity' => Icons.phonelink_lock,
      'Storage Security' => Icons.storage_rounded,
      'Authentication'   => Icons.fingerprint,
      'UI Security'      => Icons.visibility_off_outlined,
      'Communication'    => Icons.hub_outlined,
      'WebView'          => Icons.web_outlined,
      'Permissions'      => Icons.admin_panel_settings_outlined,
      _                  => Icons.security,
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasIssues = _vulnCount > 0;
    final headerColor = hasIssues ? _danger : _accent;
    final passed = widget.results.length - _vulnCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        // Section header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: headerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon(), color: headerColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.category,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: _textPri)),
                  const SizedBox(height: 2),
                  Text(
                    hasIssues
                        ? '$_vulnCount issue${_vulnCount > 1 ? 's' : ''} found'
                        : 'All checks passed',
                    style: TextStyle(fontSize: 12, color: headerColor, fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$passed / ${widget.results.length}',
                    style: const TextStyle(fontSize: 11, color: _textSec)),
                const SizedBox(height: 5),
                SizedBox(
                  width: 44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: passed / widget.results.length,
                      backgroundColor: _border,
                      valueColor: AlwaysStoppedAnimation(headerColor),
                      minHeight: 5,
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _expanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textSec),
              ),
            ]),
          ),
        ),
        // Result tiles
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _expanded
              ? Column(children: [
                  Container(height: 1, color: _border),
                  ...widget.results.map((r) => _ResultTile(result: r, isLast: r == widget.results.last)),
                ])
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

class _ResultTile extends StatefulWidget {
  final SecurityCheckResult result;
  final bool isLast;
  const _ResultTile({required this.result, required this.isLast});

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  bool _expanded = false;

  String get _typeName {
    final raw = widget.result.type.toString().split('.').last;
    final spaced = raw.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
    if (spaced.isEmpty) return raw;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final vuln = widget.result.isVulnerable;
    final color = vuln ? _danger : _accent;

    return Column(children: [
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: widget.isLast && !_expanded
            ? const BorderRadius.vertical(bottom: Radius.circular(18))
            : BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_typeName,
                    style: const TextStyle(
                        fontSize: 13.5, color: _textPri, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vuln ? 'FAIL' : 'PASS',
                  style: TextStyle(
                      fontSize: 10, color: color,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
              ),
            ]),
            // Expanded message
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(left: 18, top: 8),
                      child: Text(widget.result.message,
                          style: const TextStyle(
                              fontSize: 12.5, color: _textSec, height: 1.5)),
                    )
                  : const SizedBox.shrink(),
            ),
          ]),
        ),
      ),
      if (!widget.isLast) Container(height: 1, color: _border.withValues(alpha: 0.5)),
    ]);
  }
}

// ── Quick Result Bottom Sheet ─────────────────────────────────────────────────

class QuickResultSheet extends StatelessWidget {
  final String label;
  final SecurityCheckResult result;
  const QuickResultSheet({super.key, required this.label, required this.result});

  @override
  Widget build(BuildContext context) {
    final vuln = result.isVulnerable;
    final color = vuln ? _danger : _accent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 28),
        // Icon badge
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: Icon(
            vuln ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            color: color, size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textPri)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            vuln ? 'VULNERABLE' : 'SECURE',
            style: TextStyle(fontSize: 12, color: color,
                fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Text(result.message,
              style: const TextStyle(fontSize: 14, color: _textSec, height: 1.6)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}

// ── Scanning Overlay Card ─────────────────────────────────────────────────────

class _ScanningCard extends StatefulWidget {
  const _ScanningCard();
  @override
  State<_ScanningCard> createState() => _ScanningCardState();
}

class _ScanningCardState extends State<_ScanningCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: _accent.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Transform.rotate(
            angle: _ctrl.value * 2 * math.pi,
            child: child,
          ),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(Icons.radar_rounded, size: 44, color: _accent),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Scanning Device',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _textPri)),
        const SizedBox(height: 6),
        const Text('Running 31 security checks…',
            style: TextStyle(fontSize: 13, color: _textSec)),
        const SizedBox(height: 22),
        SizedBox(
          width: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation(_accent),
              minHeight: 5,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Score Ring Painter ────────────────────────────────────────────────────────

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ScoreRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    // Track ring
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFF243047)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    if (progress <= 0) return;

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Page Transition ───────────────────────────────────────────────────────────

PageRouteBuilder<void> _slideRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 380),
    );
