// Stub implementations of dart:io types used by flutter_shield on WASM/web.
// All methods return safe no-op defaults — the call sites are already guarded
// by (!kIsWeb && defaultTargetPlatform == TargetPlatform.android), so these
// stubs are never actually invoked at runtime.

class ProcessResult {
  final int pid;
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;
  const ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

class Process {
  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    dynamic stdoutEncoding,
    dynamic stderrEncoding,
  }) async =>
      const ProcessResult(0, 1, '', '');
}

class File {
  final String path;
  const File(this.path);
  Future<bool> exists() async => false;
}
