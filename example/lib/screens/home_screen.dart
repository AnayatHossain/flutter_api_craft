import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/example_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExampleController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterApiCraft Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── GET ─────────────────────────────────────────────────────────
            _SectionCard(
              title: '1. GET Request',
              subtitle: 'Fetch a list of posts',
              color: Colors.blue,
              onTap: controller.fetchPosts,
            ),

            // ── POST ────────────────────────────────────────────────────────
            _SectionCard(
              title: '2. POST — JSON Body',
              subtitle: 'Create a new post',
              color: Colors.green,
              onTap: controller.createPost,
            ),

            // ── Bearer Auth ──────────────────────────────────────────────────
            _SectionCard(
              title: '3. Bearer Auth',
              subtitle: 'GET with Authorization header',
              color: Colors.orange,
              onTap: controller.fetchWithBearer,
            ),

            // ── Query Params ─────────────────────────────────────────────────
            _SectionCard(
              title: '4. Query Params',
              subtitle: '?_limit=3&_page=1',
              color: Colors.teal,
              onTap: controller.fetchWithParams,
            ),

            // ── Error handling ───────────────────────────────────────────────
            _SectionCard(
              title: '5. Error Snackbar',
              subtitle: 'Hit a 404 endpoint',
              color: Colors.red,
              onTap: controller.triggerError,
            ),

            // ── Response display ─────────────────────────────────────────────
            const SizedBox(height: 12),
            Obx(() {
              final result = controller.lastResult.value;
              if (result.isEmpty) return const SizedBox();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Response:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(result, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
