import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/employee_provider.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    final employeesAsync = ref.watch(employeesStreamProvider);

    //  Search Text
    final search =
    ref.watch(employeeSearchProvider).toLowerCase();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        title: const Text('Employees'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Column(
          children: [

      // ✅ Search Field
      Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          ref
              .read(employeeSearchProvider.notifier)
              .state = value.toLowerCase();
        },

        decoration: InputDecoration(
          hintText:
          'Search by name or employee ID',

          prefixIcon:
          const Icon(Icons.search),

          filled: true,
          fillColor: Colors.white,

          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 14,
          ),

          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),

            borderSide: BorderSide.none,
          ),
        ),
      ),
      ),


       Expanded(
        child: employeesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (employees) {
            // Admin ko list mein nahi dikhao
            final filtered = employees.where((e) {

              final role =
              (e['role'] ?? '').toString().toLowerCase();

              final name =
              (e['name'] ?? '').toString().toLowerCase();

              final empId =
              (e['employeeId'] ?? '').toString().toLowerCase();

              // Admin hide
              if (role == 'admin') return false;

              // Search by name or employeeId
              return name.contains(search) ||
                  empId.contains(search);

            }).toList();

            if (filtered.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No employees yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Tap + to add first employee',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = filtered[index];
                final empId = data['employeeId'] ?? '';
                final name = data['name'] ?? '';
                final role = data['role'] ?? '';
                final phone = data['phone'] ?? '';
                final status = data['status'] ?? 'active';
                final siteName = data['siteName'] ?? 'Unassigned';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(empId,
                                style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                Text('$role • $phone',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey)),
                                Text('Site: $siteName',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'active'
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(status,
                                style: TextStyle(
                                    color: status == 'active'
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          // Edit
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditEmployeeScreen(
                                    employeeId: empId,
                                    currentData: data,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Activate/Deactivate
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final newStatus =
                                status == 'active' ? 'inactive' : 'active';
                                ref
                                    .read(employeeNotifierProvider.notifier)
                                    .updateEmployee(empId, {'status': newStatus});
                              },
                              icon: Icon(
                                status == 'active'
                                    ? Icons.block
                                    : Icons.check_circle,
                                size: 16,
                              ),
                              label: Text(
                                  status == 'active' ? 'Deactivate' : 'Activate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: status == 'active'
                                    ? Colors.orange
                                    : Colors.green,
                                side: BorderSide(
                                    color: status == 'active'
                                        ? Colors.orange
                                        : Colors.green),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Delete
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  title: const Text('Delete Employee?'),
                                  content: Text(
                                      '$name ko permanently delete karna chahte ho?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref
                                    .read(employeeNotifierProvider.notifier)
                                    .deleteEmployee(empId);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),

    ]
    ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddEmployeeScreen())),
        backgroundColor: Colors.deepOrange,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Employee',
            style: TextStyle(color: Colors.white)),
      ),

    );
  }
}