import 'dart:io';
import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/utils/custom_textfield.dart';
import '../../provider/employee_provider.dart';


class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  ConsumerState<AddEmployeeScreen> createState() =>
      _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  String? selectedRole;
  String? generatedId;

  List<Map<String, String>> _parsedEmployees = [];
  bool _isUploading = false;
  String? _fileName;
  int _successCount = 0;
  int _failCount = 0;

  final List<String> roles = ['employee', 'supervisor'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNextId();
  }

  Future<void> _loadNextId() async {
    // ✅ Provider se ID generate karo
    final id = await ref
        .read(employeeNotifierProvider.notifier)
        .generateEmployeeId();
    setState(() => generatedId = id);
  }

  Future<void> _submitManual() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRole == null) {
      _showSnack('Role select karo');
      return;
    }

    final adminUid = FirebaseAuth.instance.currentUser!.uid;

    // ✅ Provider se add karo
    final empId = await ref
        .read(employeeNotifierProvider.notifier)
        .addEmployee(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
      role: selectedRole!,
      siteId: 'unassigned',
      createdBy: adminUid,
    );

    if (!mounted) return;

    if (empId != null) {
      _showSuccessDialog(empId);
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      addressController.clear();
      setState(() => selectedRole = null);
      await _loadNextId();
    } else {
      _showSnack('Error adding employee');
    }
  }

  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() => _fileName = file.name);

      final bytes = file.bytes ?? File(file.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) { _showSnack('Excel empty hai'); return; }

      final List<Map<String, String>> employees = [];
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        final name = row[0]?.value?.toString().trim() ?? '';
        final phone = row[1]?.value?.toString().trim() ?? '';
        final email = row[2]?.value?.toString().trim() ?? '';
        final address = row[3]?.value?.toString().trim() ?? '';
        final role = row[4]?.value?.toString().trim().toLowerCase() ?? 'employee';
        if (name.isEmpty || phone.isEmpty) continue;
        employees.add({'name': name, 'phone': phone,
          'email': email, 'address': address, 'role': role});
      }

      setState(() => _parsedEmployees = employees);
      _showSnack('${employees.length} employees ready');
    } catch (e) {
      _showSnack('File error: $e');
    }
  }

  Future<void> _uploadBulk() async {
    if (_parsedEmployees.isEmpty) return;
    setState(() { _isUploading = true; _successCount = 0; _failCount = 0; });

    final adminUid = FirebaseAuth.instance.currentUser!.uid;

    for (final emp in _parsedEmployees) {
      final result = await ref
          .read(employeeNotifierProvider.notifier)
          .addEmployee(
        name: emp['name']!,
        phone: emp['phone']!,
        email: emp['email'] ?? '',
        address: emp['address'] ?? '',
        role: emp['role'] ?? 'employee',
        siteId: 'unassigned',
        createdBy: adminUid,
      );
      if (result != null) { _successCount++; } else { _failCount++; }
    }

    setState(() { _isUploading = false; _parsedEmployees = []; _fileName = null; });
    if (!mounted) return;
    _showBulkResultDialog();
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showSuccessDialog(String empId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Employee Added!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepOrange.shade200),
              ),
              child: Column(children: [
                const Text('Employee ID',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(empId,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: Colors.deepOrange, letterSpacing: 2)),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Ye ID employee ko do taki wo login kar sake.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        actions: [TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'))],
      ),
    );
  }

  void _showBulkResultDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_failCount == 0 ? Icons.check_circle : Icons.warning_amber,
                color: _failCount == 0 ? Colors.green : Colors.orange, size: 64),
            const SizedBox(height: 16),
            const Text('Upload Complete!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ResultBadge(count: _successCount, label: 'Success', color: Colors.green),
                _ResultBadge(count: _failCount, label: 'Failed', color: Colors.red),
              ],
            ),
          ],
        ),
        actions: [TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'))],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Provider state watch karo
    final employeeState = ref.watch(employeeNotifierProvider);
    final isLoading = employeeState is AsyncLoading;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add Employee'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: 'Manual'),
            Tab(icon: Icon(Icons.upload_file), text: 'Excel/CSV'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualTab(isLoading),
          _buildExcelTab(),
        ],
      ),
    );
  }

  Widget _buildManualTab(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.deepOrange.shade100),
              ),
              child: Row(children: [
                const Icon(Icons.badge_outlined, color: Colors.deepOrange, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Auto Generated ID',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(generatedId ?? 'Generating...',
                      style: const TextStyle(fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange, letterSpacing: 2)),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            CustomTextField(controller: nameController, hintText: 'Full name',
                labelText: 'Full Name', prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12)),
                child: const Text('+91', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Expanded(child: CustomTextField(controller: phoneController,
                  hintText: '10 digit number', labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.length < 10 ? 'Valid number required' : null)),
            ]),
            const SizedBox(height: 14),
            CustomTextField(controller: emailController, hintText: 'Email address',
                labelText: 'Email', keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null),
            const SizedBox(height: 14),
            CustomTextField(controller: addressController, hintText: 'Home address',
                labelText: 'Address', prefixIcon: Icons.home_outlined, maxLines: 2),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: InputDecoration(labelText: 'Role',
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              hint: const Text('Select role'),
              items: roles.map((r) => DropdownMenuItem(value: r,
                  child: Text(r[0].toUpperCase() + r.substring(1)))).toList(),
              onChanged: (val) => setState(() => selectedRole = val),
              validator: (v) => v == null ? 'Role select karo' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitManual,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Add Employee',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcelTab() {
    // Same as before — bas _uploadBulk mein provider use ho raha hai
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade100)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Text('Excel Format', style: TextStyle(fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700)),
              ]),
              const SizedBox(height: 10),
              Table(
                border: TableBorder.all(color: Colors.blue.shade200, width: 0.5),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue.shade100),
                    children: ['A: name', 'B: phone', 'C: email', 'D: address', 'E: role']
                        .map((h) => Padding(padding: const EdgeInsets.all(6),
                        child: Text(h, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))))
                        .toList(),
                  ),
                  TableRow(
                    children: ['Rahul', '9876543210', 'r@g.com', 'Bhopal', 'employee']
                        .map((v) => Padding(padding: const EdgeInsets.all(6),
                        child: Text(v, style: const TextStyle(fontSize: 10, color: Colors.grey))))
                        .toList(),
                  ),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _pickExcelFile,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrange.shade200, width: 1.5),
                  borderRadius: BorderRadius.circular(14), color: Colors.white),
              child: Column(children: [
                Icon(_fileName != null ? Icons.check_circle : Icons.upload_file,
                    size: 48, color: _fileName != null ? Colors.green : Colors.deepOrange),
                const SizedBox(height: 12),
                Text(_fileName ?? 'Tap to select Excel/CSV file',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: _fileName != null ? Colors.green : Colors.deepOrange)),
                if (_fileName == null)
                  const Text('.xlsx, .xls, .csv supported',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          ),
          if (_parsedEmployees.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('${_parsedEmployees.length} employees found',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 10),
            ..._parsedEmployees.take(5).map((emp) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(child: Text(emp['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(emp['role'] ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.orange))),
              ]),
            )),
            if (_parsedEmployees.length > 5)
              Text('+ ${_parsedEmployees.length - 5} more...',
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadBulk,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                icon: _isUploading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...'
                    : 'Upload ${_parsedEmployees.length} Employees',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _ResultBadge({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$count', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(color: color, fontSize: 13)),
    ]);
  }
}