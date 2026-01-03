import 'package:flutter/material.dart';
import 'package:flutter_shield/flutter_shield.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Shield Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SecurityCheckScreen(),
    );
  }
}

class SecurityCheckScreen extends StatefulWidget {
  const SecurityCheckScreen({super.key});

  @override
  State<SecurityCheckScreen> createState() => _SecurityCheckScreenState();
}

class _SecurityCheckScreenState extends State<SecurityCheckScreen> {
  SecurityReport? _report;
  bool _isLoading = false;

  Future<void> _runSecurityCheck() async {
    setState(() => _isLoading = true);

    try {
      final report = await FlutterShield.performFullSecurityCheck();
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _runIndividualCheck(String checkName) async {
    SecurityCheckResult? result;

    try {
      switch (checkName) {
        case 'Root/Jailbreak':
          result = await FlutterShield.checkRootedJailbroken();
          break;
        case 'Debuggable':
          result = await FlutterShield.checkDebuggable();
          break;
        case 'USB Debugging':
          result = await FlutterShield.checkUsbDebugging();
          break;
        case 'Emulator':
          result = await FlutterShield.checkEmulator();
          break;
        default:
          return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(checkName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result!.isVulnerable ? '⚠️ Vulnerable' : '✅ Secure',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.isVulnerable ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(result.message),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Shield'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
          ? _buildInitialView()
          : _buildReportView(),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Device Security Check',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Run a comprehensive security check to detect vulnerabilities',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _runSecurityCheck,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Full Security Check'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Or run individual checks:'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickCheckButton('Root/Jailbreak'),
              _buildQuickCheckButton('Debuggable'),
              _buildQuickCheckButton('USB Debugging'),
              _buildQuickCheckButton('Emulator'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCheckButton(String name) {
    return OutlinedButton(
      onPressed: () => _runIndividualCheck(name),
      child: Text(name),
    );
  }

  Widget _buildReportView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildVulnerabilitiesList(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _runSecurityCheck,
          icon: const Icon(Icons.refresh),
          label: const Text('Run Again'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final isSecure = _report!.isSecure;
    return Card(
      color: isSecure ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isSecure ? Icons.check_circle : Icons.warning,
                  size: 48,
                  color: isSecure ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSecure ? 'Device Secure' : 'Vulnerabilities Found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSecure ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_report!.vulnerabilitiesFound} of ${_report!.totalChecks} checks failed',
                        style: TextStyle(
                          color: isSecure ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVulnerabilitiesList() {
    if (_report!.isSecure) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('All security checks passed! ✅'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detected Vulnerabilities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...(_report!.vulnerabilities.map(_buildVulnerabilityCard)),
        const SizedBox(height: 16),
        const Text(
          'Passed Checks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...(_report!.results
            .where((r) => !r.isVulnerable)
            .map(_buildPassedCheckCard)),
      ],
    );
  }

  Widget _buildVulnerabilityCard(SecurityCheckResult result) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.red),
        title: Text(
          result.type.toString().split('.').last,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(result.message),
      ),
    );
  }

  Widget _buildPassedCheckCard(SecurityCheckResult result) {
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(result.type.toString().split('.').last),
        subtitle: Text(result.message),
      ),
    );
  }
}