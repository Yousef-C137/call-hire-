import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../choice_screen.dart';

class JobSeekerHome extends StatefulWidget {
  const JobSeekerHome({super.key});

  @override
  State<JobSeekerHome> createState() => _JobSeekerHomeState();
}

class _JobSeekerHomeState extends State<JobSeekerHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  String selectedCategory = 'All';
  List<dynamic> jobs = [];
  List<dynamic> myApplications = [];
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
    final result = await ApiService.getJobs(
      category: selectedCategory,
      search: searchQuery,
    );
    if (mounted) setState(() { jobs = result; loadingJobs = false; });
  }

  Future<void> _loadApplications() async {
    setState(() => loadingApps = true);
    final result = await ApiService.getMyApplications();
    if (mounted) setState(() { myApplications = result; loadingApps = false; });
  }

  Future<void> _apply(Map<String, dynamic> job) async {
    final result = await ApiService.applyToJob(job['job_id']);
    if (!mounted) return;
    if (result['statusCode'] == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied for ${job['title']}!'), backgroundColor: Colors.green),
      );
      _loadApplications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to apply.'), backgroundColor: Colors.red),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade900,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Find Your Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
            Text(currentUser?['name'] ?? 'Welcome!', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
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
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Browse Jobs', icon: Icon(Icons.search)),
            Tab(text: 'My Applications', icon: Icon(Icons.assignment_turned_in)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildBrowseTab(), _buildApplicationsTab()],
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade900,
          child: TextField(
            onChanged: (value) {
              searchQuery = value;
              _loadJobs();
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search jobs, companies...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        _buildCategoryFilter(),
        Expanded(
          child: loadingJobs
              ? const Center(child: CircularProgressIndicator())
              : jobs.isEmpty
                  ? const Center(child: Text('No jobs found.'))
                  : RefreshIndicator(
                      onRefresh: _loadJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) => _buildJobCard(jobs[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Customer Service', 'Calling', 'Technical Support'];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) { selectedCategory = cat; _loadJobs(); },
              selectedColor: Colors.blue.shade900,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.blue.shade900),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.blue.shade900),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => _showJobDetails(job),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.business, color: Colors.blue.shade900),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text(job['company_name'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildTag(job['category'] ?? ''),
                  const SizedBox(width: 8),
                  if (job['experience_required'] != null) _buildTag(job['experience_required']),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job['salary'] ?? 'Salary not specified',
                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
                  ElevatedButton(
                    onPressed: () => _showJobDetails(job),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text(job['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(job['company_name'] ?? '', style: TextStyle(fontSize: 18, color: Colors.blue.shade900)),
            const Divider(height: 40),
            const Text('Job Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(job['description'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),
            const SizedBox(height: 20),
            if (job['experience_required'] != null) _buildRequirementItem('Experience: ${job['experience_required']}'),
            if (job['language'] != null) _buildRequirementItem('Language: ${job['language']} (${job['language_level'] ?? ''})'),
            if (job['category'] != null) _buildRequirementItem('Category: ${job['category']}'),
            if (job['location'] != null) _buildRequirementItem('Location: ${job['location']}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _apply(job),
                child: const Text('Apply Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    if (loadingApps) return const Center(child: CircularProgressIndicator());
    if (myApplications.isEmpty) return const Center(child: Text("You haven't applied for any jobs yet."));

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: myApplications.length,
        itemBuilder: (context, index) {
          final app = myApplications[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(app['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Company: ${app['company_name']}\nStatus: ${app['status']}'),
              trailing: _buildStatusIcon(app['status']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String? status) {
    if (status == 'accepted') return const Icon(Icons.check_circle, color: Colors.green);
    if (status == 'rejected') return const Icon(Icons.cancel, color: Colors.red);
    return const Icon(Icons.hourglass_empty, color: Colors.orange);
  }
}
