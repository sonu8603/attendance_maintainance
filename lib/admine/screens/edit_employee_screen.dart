import 'package:flutter/material.dart';
import '../../features/utils/custom_textfield.dart';
import '../services/employee_service.dart';

class EditEmployeeScreen extends StatefulWidget {
  final String employeeId;
  final Map<String, dynamic> currentData;

  const EditEmployeeScreen({
    super.key,
    required this.employeeId,
    required this.currentData,
  });

  @override
  State<EditEmployeeScreen> createState() =>
      _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;
  String? selectedRole;
  bool _isLoading = false;

  final List<String> roles = ['employee', 'supervisor', 'admin'];

  @override
  void initState() {
    super.initState();
    // ✅ Current data se pre-fill karo
    nameController = TextEditingController(
        text: widget.currentData['name'] ?? '');
    phoneController = TextEditingController(
        text: widget.currentData['phone'] ?? '');
    emailController = TextEditingController(
        text: widget.currentData['email'] ?? '');
    addressController = TextEditingController(
        text: widget.currentData['address'] ?? '');
    selectedRole = widget.currentData['role'];
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await EmployeeService.updateEmployee(
        widget.employeeId,
        {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'address': addressController.text.trim(),
          'role': selectedRole,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Edit ${widget.currentData['name'] ?? ''}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // Employee ID — read only
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.deepOrange.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        color: Colors.deepOrange),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text('Employee ID',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey)),
                        Text(
                          widget.employeeId,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CustomTextField(
                controller: nameController,
                hintText: 'Full name',
                labelText: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: phoneController,
                hintText: '10 digit number',
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) =>
                v == null || v.length < 10
                    ? 'Valid number required'
                    : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: emailController,
                hintText: 'Email address',
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: addressController,
                hintText: 'Home address',
                labelText: 'Address',
                prefixIcon: Icons.home_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              // Role dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  prefixIcon:
                  const Icon(Icons.work_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: roles
                    .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r[0].toUpperCase() +
                      r.substring(1)),
                ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => selectedRole = val),
                validator: (v) =>
                v == null ? 'Role select karo' : null,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _update,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}