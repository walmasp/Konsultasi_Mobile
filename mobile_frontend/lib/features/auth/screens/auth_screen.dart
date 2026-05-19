import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../booking/screens/home_screen.dart';

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

          if (response.statusCode == 200) {
            // Simpan Token JWT baru ke SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('jwt_token', response.data['token']);
            await prefs.setString('username', response.data['username']);

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
        
        // Simpan token ke SharedPreferences (Untuk otorisasi API)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', response.data['token']);
        await prefs.setString('username', response.data['username']);

        // Simpan kredensial ke Secure Storage (Untuk Biometrik berikutnya)
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
      _showSnackbar(e.response?.data['message'] ?? 'Terjadi kesalahan server');
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
        content: Text(message), 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // ==========================================
              // TAMPILAN 1: ADA AKUN TERSIMPAN (BIOMETRIK)
              // ==========================================
              if (_hasSavedAccount && !_forceManualLogin) ...[
                const Icon(Icons.fingerprint_rounded, size: 90, color: Color(0xFF007AFF)),
                const SizedBox(height: 32),
                const Text(
                  'Selamat Datang Kembali',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  _lastUsername,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Color(0xFF007AFF), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 48),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Masuk dengan Sidik Jari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _clearSession,
                  child: const Text('Login dengan Akun Lain', style: TextStyle(color: Colors.black54)),
                ),
              ] 
              
              // ==========================================
              // TAMPILAN 2: BELUM ADA AKUN / MANUAL LOGIN
              // ==========================================
              else ...[
                const Icon(Icons.shield_rounded, size: 80, color: Color(0xFF007AFF)),
                const SizedBox(height: 24),
                Text(
                  _isLoginMode ? 'Masuk Sesi Anonim' : 'Buat ID Anonim',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                const SizedBox(height: 40),
                
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username Samaran',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isLoginMode ? 'Login' : 'Daftar Akun Anonim', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                
                TextButton(
                  onPressed: () => setState(() {
                    _isLoginMode = !_isLoginMode;
                    _passwordController.clear();
                  }),
                  child: Text(_isLoginMode ? 'Belum punya ID? Buat Akun' : 'Sudah punya ID? Login', style: const TextStyle(color: Color(0xFF007AFF))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}