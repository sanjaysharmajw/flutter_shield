# Changelog

## 1.0.0

### Initial Release

#### Features
- ✅ Complete coverage of 30 security vulnerabilities
- ✅ Support for both Android and iOS platforms
- ✅ Comprehensive security reporting
- ✅ Individual check methods for targeted testing
- ✅ Full security scan functionality

#### Device Integrity
- Root/Jailbreak detection with multiple methods
- Debuggable app detection
- USB debugging status check (Android)
- Emulator/Simulator detection
- Basic malware exposure detection

#### Storage Security
- Local storage security analysis
- Plaintext data detection
- Keychain/Keystore validation framework
- File permissions checking
- External storage analysis
- Backup configuration checking

#### Authentication
- Biometric handling validation
- Biometric bypass detection
- Screen lock enforcement checking

#### UI Security
- Screenshot restriction checking
- Screen recording detection
- Clipboard security analysis
- Overlay attack detection framework
- Background data exposure checking
- Recent apps exposure detection

#### Communication
- IPC security analysis
- Intent hijacking detection (Android)
- Broadcast receiver exposure checking (Android)
- Deep link security validation

#### WebView Security
- WebView debugging detection
- JavaScript interface security checking

#### Permissions & Runtime
- Runtime permission validation
- Autofill security checking
- Sensor abuse detection framework

#### Other
- Device time trust validation
- Side-channel attack detection framework

### Platform Support
- Android: API 21+ (Android 5.0 Lollipop)
- iOS: 12.0+

### Known Limitations
- Some checks require app-specific implementation
- Malware detection is basic and should be enhanced
- WebView checks require runtime inspection
- Certificate pinning not included (coming in future release)