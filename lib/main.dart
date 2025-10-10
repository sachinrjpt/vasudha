import 'package:flutter/material.dart';
import 'screens/farmer_registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/constants.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';   // ✅ import your API service
import 'services/master_service.dart'; // ✅ add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔴 हर बार restart पर logout करने के लिए token clear कर दो
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  runApp(const VasudhaApp());
}


class VasudhaApp extends StatelessWidget {
  const VasudhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vasudha Login',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const LoginPage(), // ✅ Default page is Login
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false; // ✅ loader state

  Future<void> _handleLogin() async {
    final login = emailController.text.trim();
    final password = passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter login and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    final res = await ApiService.loginEmployee(login, password);

    setState(() => isLoading = false);

    if (res["ok"] == true) {
  // ✅ Success
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(res["message"] ?? "Login successful")),
  );

  // 🔄 Load masters after login success
  await MasterService.reload();

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const DashboardScreen()),
  );
}
 else {
      // ❌ Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Login failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo.png',
                  height: isWeb ? 100 : 80,
                ),
                const SizedBox(height: 8),

                const Text(
                  "ઉથાન",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const Text(
                  "Utthan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Sign In",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "Please enter your details to sign in",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Login (email / phone / employee id)
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email / Phone / Employee Id",
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // ✅ brand green
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading ? null : _handleLogin,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Sign In",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
