import 'package:flutter/material.dart';
import 'screens/farmer_registration_screen.dart';
import '../widgets/auto_translate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vasudha/widgets/auto_text.dart';
import 'utils/constants.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart'; // ✅ import your API service
import 'services/master_service.dart'; // ✅ add this import
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LanguageProvider())],
      child: const VasudhaApp(),
    ),
  );
}

class VasudhaApp extends StatelessWidget {
  const VasudhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vasudha Login',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final prefs = snapshot.data!;
          bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;
          String userType = prefs.getString("userType") ?? "employee";

          if (isLoggedIn) {
            return DashboardScreen(userType: userType);
          }

          return const LoginPage();
        },
      ),
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
        SnackBar(content: AutoText("Please enter login and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    final res = await ApiService.loginEmployee(login, password);

    setState(() => isLoading = false);

    if (res["ok"] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isLoggedIn", true);
      await prefs.setString("userType", res["user_type"] ?? "employee");

      if ((res["user_type"] ?? "").toString().toLowerCase() == "farmer") {
        await prefs.setString("farmerName", res["user"]["name"] ?? "");
        await prefs.setString("farmerEmail", res["user"]["email"] ?? "");
        await prefs.setString("farmerPhone", res["user"]["phone"] ?? "");
        await prefs.setString(
          "farmerImage",
          res["user"]["profile_image"] ?? "",
        );
      }
      // ✅ Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Login successful")),
      );

      // 🔄 Load masters after login success
      await MasterService.reload();

      String userType = (res["user_type"] ?? "employee")
          .toString()
          .toLowerCase();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            userType: userType,
            userData: userType == "farmer"
                ? res["user"]
                : null, // <-- pass farmer data
          ),
        ),
      );
    } else {
      // ❌ Error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res["message"] ?? "Login failed")));
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
                Image.asset('assets/logo.png', height: isWeb ? 100 : 80),
                const SizedBox(height: 8),

                AutoText(
                  "ઉથાન",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                AutoText(
                  "Utthan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                ),

                const SizedBox(height: 20),

                AutoText(
                  "Sign In",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                AutoText(
                  "Please enter your details to sign in",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Login (email / phone / employee id)
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email / Phone / Employee Id",
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
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
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                        : AutoText(
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
