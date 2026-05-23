import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../booking/screens/home_screen.dart';

// ─── Sanctuary Design Tokens ────────────────────────────────────────────────
const _kPrimary      = Color(0xFF5C6BC0);
const _kPrimaryLight = Color(0xFFE8EAF6);
const _kAccent       = Color(0xFF26A69A);
const _kBg           = Color(0xFFF0F2F8);
const _kCardBg       = Color(0xFFFFFFFF);
const _kTextPrimary  = Color(0xFF1C1F33);
const _kTextSub      = Color(0xFF6B7280);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final ApiClient _api = ApiClient();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Variabel Sesi
  bool _hasSavedAccount = false;
  bool _forceManualLogin = false; 
  String _lastUsername = '';

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  // Cek apakah ada data login tersimpan di Secure Storage
  Future<void> _checkExistingSession() async {
    String? savedUsername = await _secureStorage.read(key: 'saved_username');
    String? savedPassword = await _secureStorage.read(key: 'saved_password');
    
    if (savedUsername != null && savedPassword != null) {
      setState(() {
        _hasSavedAccount = true;
        _lastUsername = savedUsername;
      });
    }
  }

  // --- LOGIKA LOGIN BIOMETRIK (HIT API BACKGROUND) ---
  Future<void> _authenticateBiometric() async {
    try {
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari untuk masuk sebagai $_lastUsername',
      );
      
      if (authenticated) {
        setState(() => _isLoading = true);
        
        String? savedUsername = await _secureStorage.read(key: 'saved_username');
        String? savedPassword = await _secureStorage.read(key: 'saved_password');

        if (savedUsername != null && savedPassword != null) {
          // Hit API untuk dapatkan Token Fresh
          final response = await _api.dio.post('/auth/login', data: {
            'username': savedUsername,
            'password': savedPassword,
          });

          // --- GANTI BAGIAN INI ---
        if (response.statusCode == 200) {
  // Simpan Token JWT
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', response.data['token']);
  
  // Perhatikan: Akses ke 'user' terlebih dahulu
          await prefs.setString('username', response.data['user']['username']);
          await prefs.setInt('user_id', response.data['user']['id']); // Sangat penting untuk fitur Chat nanti

        if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      }
        }
      }
    } on DioException {
      _showSnackbar('Sesi kadaluarsa atau server bermasalah. Silakan login manual.');
      _clearSession(); // Paksa login manual jika API gagal
    } catch (e) {
      _showSnackbar('Error Biometrik: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA LOGIN MANUAL & REGISTER ---
  Future<void> _submitForm() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackbar('Username dan Password wajib diisi!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
  // PROSES LOGIN
  final response = await _api.dio.post('/auth/login', data: {
    'username': _usernameController.text,
    'password': _passwordController.text,
  });
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('jwt_token', response.data['token']);
  await prefs.setString('username', response.data['user']['username']); // Dulu: ['username']
  await prefs.setInt('user_id', response.data['user']['id']);

  // Simpan kredensial ke Secure Storage
  await _secureStorage.write(key: 'saved_username', value: _usernameController.text);
  await _secureStorage.write(key: 'saved_password', value: _passwordController.text);

  if (mounted) {
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => const HomeScreen()));
  }
} else {
        // PROSES REGISTER
        await _api.dio.post('/auth/register', data: {
          'username': _usernameController.text,
          'password': _passwordController.text,
        });
        
        _showSnackbar('Akun anonim berhasil dibuat! Silakan Login.');
        setState(() {
          _isLoginMode = true; // Pindah otomatis ke layar login
          _passwordController.clear(); // Bersihkan password demi keamanan
        });
      }
    } on DioException catch (e) {
       print("=== ERROR KONEKSI ===");
  print("Tipe Error: ${e.type}"); // Ini akan ngasih tau apakah Timeout atau Connection Refused
  print("Pesan Asli: ${e.message}");
  print("Status Code: ${e.response?.statusCode}");
  print("Pesan Server: ${e.response?.data}");
  print("=====================");
     } finally {
      setState(() => _isLoading = false);
    }
  }

  // Hapus Sesi (Jika user klik Login dengan akun lain)
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('username');
    
    await _secureStorage.delete(key: 'saved_username');
    await _secureStorage.delete(key: 'saved_password');

    setState(() {
      _hasSavedAccount = false;
      _forceManualLogin = true;
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kTextPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Decorative gradient blobs ──────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kPrimary.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kAccent.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          // ── Main Content ───────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  if (_hasSavedAccount && !_forceManualLogin)
                    _buildBiometricView()
                  else
                    _buildManualLoginView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAMPILAN 1: BIOMETRIK ──────────────────────────────────────────────────
  Widget _buildBiometricView() {
    return Column(
      children: [
        // Fingerprint glow badge
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF7986CB), _kPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.38),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.fingerprint_rounded, size: 58, color: Colors.white),
        ),
        const SizedBox(height: 36),
        const Text(
          'Selamat Datang\nKembali',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        // Username chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: _kPrimaryLight,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            _lastUsername,
            style: const TextStyle(
              fontSize: 16,
              color: _kPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 52),

        // Biometric Button
        _GradientButton(
          onPressed: _isLoading ? null : _authenticateBiometric,
          isLoading: _isLoading,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint_rounded, size: 20),
              SizedBox(width: 10),
              Text('Masuk dengan Sidik Jari',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _clearSession,
          child: const Text(
            'Login dengan Akun Lain',
            style: TextStyle(color: _kTextSub, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── TAMPILAN 2: MANUAL LOGIN / REGISTER ───────────────────────────────────
  Widget _buildManualLoginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Shield icon with gradient
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7986CB), _kPrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.32),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded, size: 50, color: Colors.white),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _isLoginMode ? 'Masuk Sesi\nAnonim' : 'Buat ID\nAnonim',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
            height: 1.15,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLoginMode
              ? 'Identitas aslimu tidak akan pernah diketahui'
              : 'Buat akun tanpa nama asli atau email',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _kTextSub, height: 1.4),
        ),
        const SizedBox(height: 40),

        // Input Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.07),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _StyledTextField(
                controller: _usernameController,
                hint: 'Username Samaran',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _StyledTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _kTextSub,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _GradientButton(
          onPressed: _isLoading ? null : _submitForm,
          isLoading: _isLoading,
          child: Text(
            _isLoginMode ? 'Login' : 'Daftar Akun Anonim',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() {
            _isLoginMode = !_isLoginMode;
            _passwordController.clear();
          }),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(
                  text: _isLoginMode
                      ? 'Belum punya ID? '
                      : 'Sudah punya ID? ',
                  style: const TextStyle(color: _kTextSub),
                ),
                TextSpan(
                  text: _isLoginMode ? 'Buat Akun' : 'Login',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Shared UI Components ───────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;

  const _GradientButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(colors: [Colors.grey[300]!, Colors.grey[300]!])
            : const LinearGradient(
                colors: [Color(0xFF7986CB), _kPrimary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
          color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextSub, fontSize: 14),
        prefixIcon: Icon(icon, color: _kPrimary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _kBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}