import 'package:flutter/material.dart';

class SupportTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SupportTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 0.5,

      margin: const EdgeInsets.only(bottom: 14),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      child: ListTile(

        leading: CircleAvatar(
          backgroundColor:
          Colors.deepOrange.shade50,

          child: Icon(
            icon,
            color: Colors.deepOrange,
          ),
        ),

        title: Text(
          title,

          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(subtitle),

        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
        ),

        onTap: onTap,
      ),
    );
  }
}