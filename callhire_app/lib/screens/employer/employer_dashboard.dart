import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../choice_screen.dart';
import 'post_job_screen.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> myJobs = [];
  List<dynamic> applications = [];
  bool loadingJobs = true;
  bool loadingApps = true;
  Map<String, dynamic>? currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
    _loadJobs();
    _loadApplications();
  }

  Future<void> _loadUser() async {
    currentUser = await ApiService.getUser();
    if (mounted) setState(() {});
  }

  Future<void> _loadJobs() async {
    setState(() => loadingJobs = true);
    final result = await ApiService.getMyJobs();
    if (mounted) setState(() { myJobs = result; loadingJobs = false; });
  }

  Future<void> _loadApplications() async {
    setState(() => loadingApps = true);
    final result = await ApiService.getEmployerApplications();
    if (mounted) setState(() { applications = result; loadingApps = false; });
  }

  Future<void> _updateStatus(int applicationId, String status) async {
    final result = await ApiService.updateApplicationStatus(applicationId, status);
    if (!mounted) return;
    if (result['statusCode'] == 200) {
      _loadApplications();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $status.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to update.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteJob(int jobId) async {
    final result = await ApiService.deleteJob(jobId);
    if (!mounted) return;
    if (result['statusCode'] == 200) {
      _loadJobs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job deleted.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ApiService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChoiceScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My Jobs', icon: Icon(Icons.work)),
            Tab(text: 'Applications', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildJobsTab(), _buildApplicationsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade900,
        onPressed: () async {
          final posted = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen()));
          if (posted == true) _loadJobs();
        },
        label: const Text('Post a Job', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildJobsTab() {
    if (loadingJobs) return const Center(child: CircularProgressIndicator());
    if (myJobs.isEmpty) return const Center(child: Text("You haven't posted any jobs yet."));

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        itemCount: myJobs.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final job = myJobs[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(job['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${job['category'] ?? ''} • ${job['salary'] ?? 'No salary listed'}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteJob(job['job_id']),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationsTab() {
    if (loadingApps) return const Center(child: CircularProgressIndicator());
    if (applications.isEmpty) return const Center(child: Text('No applications received yet.'));

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        itemCount: applications.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final app = applications[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _EmployerAppDetailScreen(
                  app: app,
                  onUpdateStatus: _updateStatus,
                ),
              ),
            ),
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(app['seeker_name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        _buildStatusChip(app['status'] ?? 'pending'),
                      ],
                    ),
                    Text('Applied for: ${app['title']}'),
                    if (app['skills'] != null) Text('Skills: ${app['skills']}', style: const TextStyle(color: Colors.grey)),
                    if (app['experience_years'] != null) Text('Experience: ${app['experience_years']} years', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'accepted') color = Colors.green;
    if (status == 'rejected') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
class _EmployerAppDetailScreen extends StatelessWidget {
  final Map<String, dynamic> app;
  final Future<void> Function(int, String) onUpdateStatus;

  const _EmployerAppDetailScreen({required this.app, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Applicant Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32, backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.person, color: Colors.blue.shade900, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app['seeker_name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Applied for: ${app['title']}', style: TextStyle(color: Colors.blue.shade900, fontSize: 14)),
                    ],
                  ),
                ),
                _buildStatusChip(app['status'] ?? 'pending'),
              ],
            ),
            const Divider(height: 40),
            if (app['skills'] != null) _buildDetailRow(Icons.star, 'Skills', app['skills']),
            if (app['experience_years'] != null) _buildDetailRow(Icons.work_history, 'Experience', '${app['experience_years']} years'),
            if (app['email'] != null) _buildDetailRow(Icons.email, 'Email', app['email']),
            if (app['phone'] != null) _buildDetailRow(Icons.phone, 'Phone', app['phone']),
            if (app['language'] != null) _buildDetailRow(Icons.language, 'Language', '${app['language']} (${app['language_level'] ?? ''})'),
            const SizedBox(height: 40),
            if (app['status'] == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        onUpdateStatus(app['application_id'], 'rejected');
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onUpdateStatus(app['application_id'], 'accepted');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  'This application has been ${app['status']}.',
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade900, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status == 'accepted') color = Colors.green;
    if (status == 'rejected') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}