import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';

/// Web app shell with persistent navigation
class WebShell extends ConsumerStatefulWidget {
  final Widget child;
  
  const WebShell({super.key, required this.child});

  @override
  ConsumerState<WebShell> createState() => _WebShellState();
}

class _WebShellState extends ConsumerState<WebShell> {
  bool _isDrawerOpen = false;
  String? _selectedLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          widget.child,
          _buildFloatingButtons(),
        ],
      ),
      footer: _buildFooter(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppTheme.kPrimaryColor),
        onPressed: () => setState(() => _isDrawerOpen = !_isDrawerOpen),
      ),
      title: Row(
        children: [
          Image.asset(
            'assets/images/app_logo.png',
            height: 40,
            errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: AppTheme.kPrimaryColor),
          ),
          const SizedBox(width: 12),
          const Text(
            'Restaurant Name',
            style: TextStyle(
              color: AppTheme.kPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        // Navigation links (desktop)
        if (MediaQuery.of(context).size.width > 768) ...[
          _buildNavLink('Home', '/'),
          _buildNavLink('Menu', '/menu'),
          _buildNavLink('Offers', '/offers'),
          _buildNavLink('Gallery', '/gallery'),
          _buildNavLink('About', '/about'),
          _buildNavLink('Contact', '/contact'),
        ],
        const SizedBox(width: 16),
        // Language selector
        PopupMenuButton<String>(
          icon: const Icon(Icons.language, color: AppTheme.kPrimaryColor),
          onSelected: (lang) => setState(() => _selectedLanguage = lang),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'en', child: Text('English')),
            const PopupMenuItem(value: 'hi', child: Text('हिंदी')),
          ],
        ),
      ],
    );
  }

  Widget _buildNavLink(String text, String route) {
    return TextButton(
      onPressed: () {
        // Navigate using GoRouter
      },
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.kTextPrimary),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.kPrimaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.restaurant, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'Restaurant Name',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Menu'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.local_offer),
            title: const Text('Offers'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Contact'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feedback button
          FloatingActionButton.small(
            heroTag: 'feedback',
            backgroundColor: AppTheme.kPrimaryColor,
            onPressed: _showFeedbackWidget,
            child: const Icon(Icons.feedback, color: Colors.white),
          ),
          const SizedBox(height: 12),
          // WhatsApp button
          FloatingActionButton.small(
            heroTag: 'whatsapp',
            backgroundColor: Colors.green,
            onPressed: _openWhatsApp,
            child: const Icon(Icons.message, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppTheme.kSecondaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFooterSection(
                'Address',
                ['123 Restaurant Street', 'City, State 123456'],
              ),
              _buildFooterSection(
                'Contact',
                ['+91 98765 43210', 'info@restaurant.com'],
              ),
              _buildFooterSection(
                'Social',
                ['Facebook', 'Instagram', 'Twitter'],
              ),
            ],
          ),
          const Divider(color: AppTheme.kDividerColor),
          const Text(
            '© 2024 Restaurant Name. All rights reserved.',
            style: TextStyle(color: AppTheme.kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(item, style: const TextStyle(color: AppTheme.kTextSecondary)),
        )),
      ],
    );
  }

  void _showFeedbackWidget() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const FeedbackWidget(),
    );
  }

  void _openWhatsApp() {
    // Open WhatsApp with pre-filled message
    const phone = '919876543210';
    const message = 'Hello, I would like to inquire about...';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    
    // Launch URL
    html.window.open(url, '_blank');
  }
}

// ============================================================================
// FEEDBACK WIDGET
// ============================================================================

class FeedbackWidget extends StatefulWidget {
  const FeedbackWidget({super.key});

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  int _rating = 0;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate Your Experience',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Comment field
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Share your experience (optional)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_rating == 0) {
                  return 'Please select a rating';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitFeedback,
                child: const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      // Submit feedback to API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      Navigator.pop(context);
    }
  }
}
