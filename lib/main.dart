import 'package:flutter/material.dart';
import 'screens/health_monitor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const IPConfigScreen(),
    );
  }
}

class IPConfigScreen extends StatefulWidget {
  const IPConfigScreen({Key? key}) : super(key: key);

  @override
  State<IPConfigScreen> createState() => _IPConfigScreenState();
}

class _IPConfigScreenState extends State<IPConfigScreen>
    with TickerProviderStateMixin {
  final TextEditingController _ipController =
      TextEditingController(text: '192.168.1.100');

  late AnimationController _pulseController;
  late AnimationController _titlePulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.94,
      upperBound: 1.08,
    )..repeat(reverse: true);

    _titlePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titlePulse.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _connect() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty || !RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập IP hợp lệ!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => HealthMonitorScreen(esp32Ip: ip),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: true,   // 👈 CHỐNG TRÀN UI KHI MỞ BÀN PHÍM
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade400, Colors.purple.shade700],
        ),
      ),

      child: SafeArea(
        child: SingleChildScrollView(           // 👈 CUỘN UI KHI BÀN PHÍM ĐẨY LÊN
          padding: const EdgeInsets.only(bottom: 40), // chống che nút
          child: Column(
            children: [
              // ===== PHẦN TRÊN =====
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseController,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "assets/images/right_decor.jpeg",
                            width: 120,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.health_and_safety,
                              size: 110,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    AnimatedBuilder(
                      animation: _titlePulse,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.8 + 0.2 * _titlePulse.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF67E8F9),
                                Color(0xFF0EA5E9),
                                Color(0xFF1E3A8A),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              "Cristiano Prime",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 10)
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ===== PHẦN CARD =====
              Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _pulseController,
                          child: Icon(
                            Icons.health_and_safety,
                            size: 80,
                            color: Colors.blue.shade700,
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Health Monitor',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Connect to ESP32-C3',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ------ INPUT IP ------
                        TextField(
                          controller: _ipController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'ESP32 IP Address',
                            hintText: '192.168.1.100',
                            prefixIcon: const Icon(Icons.router),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 2),
                            ),
                          ),
                          onSubmitted: (_) => _connect(),
                        ),

                        const SizedBox(height: 28),

                        // ------ BUTTON ------
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton.icon(
                            onPressed: _connect,
                            icon: const Icon(Icons.link, size: 26),
                            label: const Text(
                              'CONNECT TO DEVICE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Make sure your phone and ESP32 are on the same WiFi network',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
}

}