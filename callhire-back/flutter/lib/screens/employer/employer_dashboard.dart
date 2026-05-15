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
          return Card(
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
                  const Divider(),
                  if (app['status'] == 'pending')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateStatus(app['application_id'], 'rejected'),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _updateStatus(app['application_id'], 'accepted'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          icon: const Icon(Icons.check),
                          label: const Text('Accept'),
                        ),
                      ],
                    )
                  else
                    Text('Status: ${app['status']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
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
