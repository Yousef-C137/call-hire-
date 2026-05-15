import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  final String userType;
  const SignupScreen({super.key, required this.userType});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _cvController = TextEditingController();
  final _contactController = TextEditingController();
  final _companyController = TextEditingController();
  final _industryController = TextEditingController();
  final _locationController = TextEditingController();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isSeeker = widget.userType == 'Job Seeker';
    final role = isSeeker ? 'seeker' : 'employer';

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': role,
      if (isSeeker) ...{
        'skills': _skillsController.text.trim(),
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
        'cv_url': _cvController.text.trim(),
        'contact_info': _contactController.text.trim(),
      } else ...{
        'company_name': _companyController.text.trim(),
        'industry': _industryController.text.trim(),
        'location': _locationController.text.trim(),
        'contact_info': _contactController.text.trim(),
      },
    };

    try {
      final result = await ApiService.register(data);
      if (!mounted) return;

      if (result['message'] != null && result['message'].toString().contains('successfully')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please login.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registration failed.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to server.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeeker = widget.userType == 'Job Seeker';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userType} Signup'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
              const SizedBox(height: 20),
              _field(_nameController, 'Full Name', Icons.person),
              const SizedBox(height: 15),
              _field(_emailController, 'Email Address', Icons.email, type: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _field(_passwordController, 'Password', Icons.lock, obscure: true),
              const SizedBox(height: 15),

              if (isSeeker) ...[
                _field(_skillsController, 'Skills (e.g. Sales, English)', Icons.star),
                const SizedBox(height: 15),
                _field(_experienceController, 'Years of Experience', Icons.history, type: TextInputType.number, required: false),
                const SizedBox(height: 15),
                _field(_cvController, 'CV Link / Info', Icons.description, required: false),
                const SizedBox(height: 15),
                _field(_contactController, 'Contact Info', Icons.phone, required: false),
              ] else ...[
                _field(_companyController, 'Company Name', Icons.business),
                const SizedBox(height: 15),
                _field(_industryController, 'Industry (e.g. BPO, Telecom)', Icons.work, required: false),
                const SizedBox(height: 15),
                _field(_locationController, 'Location', Icons.location_on, required: false),
                const SizedBox(height: 15),
                _field(_contactController, 'Contact Info', Icons.phone),
              ],

              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign Up', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => required && (v == null || v.isEmpty) ? 'Please enter $label' : null,
    );
  }
}
