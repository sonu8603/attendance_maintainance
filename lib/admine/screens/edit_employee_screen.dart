import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/utils/custom_textfield.dart';
import '../provider/employee_provider.dart';

class EditEmployeeScreen extends ConsumerStatefulWidget {
  final String employeeId;
  final Map<String, dynamic> currentData;

  const EditEmployeeScreen({
    super.key,
    required this.employeeId,
    required this.currentData,
  });

  @override
  ConsumerState<EditEmployeeScreen> createState() =>
      _EditEmployeeScreenState();
}

class _EditEmployeeScreenState
    extends ConsumerState<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;
  String? selectedRole;

  final List<String> roles = ['employee', 'supervisor', 'admin'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentData['name'] ?? '');
    phoneController = TextEditingController(text: widget.currentData['phone'] ?? '');
    emailController = TextEditingController(text: widget.currentData['email'] ?? '');
    addressController = TextEditingController(text: widget.currentData['address'] ?? '');
    selectedRole = widget.currentData['role'];
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(employeeNotifierProvider.notifier).updateEmployee(
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

    final state = ref.read(employeeNotifierProvider);
    if (state is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${state.error}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated successfully!'),
              backgroundColor: Colors.green));
      Navigator.pop(context);
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
    final isLoading =
    ref.watch(employeeNotifierProvider) is AsyncLoading;

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
          child: Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.shade100)),
              child: Row(children: [
                const Icon(Icons.badge_outlined, color: Colors.deepOrange),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Employee ID',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(widget.employeeId,
                      style: const TextStyle(fontSize: 20,
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
            CustomTextField(controller: phoneController, hintText: '10 digit number',
                labelText: 'Phone Number', keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) => v == null || v.length < 10 ? 'Valid number required' : null),
            const SizedBox(height: 14),
            CustomTextField(controller: emailController, hintText: 'Email address',
                labelText: 'Email', keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined),
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
              items: roles.map((r) => DropdownMenuItem(value: r,
                  child: Text(r[0].toUpperCase() + r.substring(1)))).toList(),
              onChanged: (val) => setState(() => selectedRole = val),
              validator: (v) => v == null ? 'Role select karo' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : _update,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}