import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/daos/bill_template_dao.dart';
import '../../shared/widgets/app_card.dart';

class SelectTemplateScreen extends ConsumerWidget {
  const SelectTemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(billTemplateDaoProvider).getAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final templates = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Template'),
          ),
          body: templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text('No templates available'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/billing/templates/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Template'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Color(template.primaryColor).withOpacity(0.1),
                          child: Icon(
                            Icons.palette,
                            color: Color(template.primaryColor),
                          ),
                        ),
                        title: Text(
                          template.brandName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (template.logoPath?.isNotEmpty == true)
                              const Text('✓ Has logo'),
                            if (template.footerText?.isNotEmpty == true)
                              Text(template.footerText!),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigate to preview with selected template
                          // The bill data is passed via GoRouter extra
                          context.go('/billing/preview', extra: {
                            'template': template,
                          });
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
