import 'package:flutter/material.dart';
import 'login_screen.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade500],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.work_outline, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                const Text('CallHire', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text(
                  'Find your dream job or the perfect candidate',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 60),
                _buildChoiceButton(context, title: 'I am an Employer', subtitle: 'Hire the best talents', icon: Icons.business, userType: 'Employer'),
                const SizedBox(height: 20),
                _buildChoiceButton(context, title: 'I am a Job Seeker', subtitle: 'Apply for your next role', icon: Icons.person_search, userType: 'Job Seeker'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(BuildContext context, {required String title, required String subtitle, required IconData icon, required String userType}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue.shade900,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen(userType: userType))),
      child: Row(
        children: [
          Icon(icon, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
