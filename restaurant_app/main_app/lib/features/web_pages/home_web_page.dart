import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/cms_repository.dart';
import '../models/cms_section.dart';
import '../../shared/widgets/web_announcement_bar.dart';
import '../../shared/widgets/web_hero_slider.dart';
import '../../shared/widgets/web_today_special.dart';
import '../../shared/widgets/web_offers_section.dart';
import '../../shared/widgets/web_menu_preview.dart';
import '../../shared/widgets/web_about_snippet.dart';
import '../../shared/widgets/web_gallery_preview.dart';
import '../../shared/widgets/web_feedback_section.dart';

class HomeWebPage extends ConsumerStatefulWidget {
  const HomeWebPage({super.key});

  @override
  ConsumerState<HomeWebPage> createState() => _HomeWebPageState();
}

class _HomeWebPageState extends ConsumerState<HomeWebPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Pre-fetch CMS data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cmsProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 300;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const WebAnnouncementBar(),
                const WebHeroSlider(),
                const WebTodaySpecial(),
                const WebOffersSection(),
                const WebMenuPreview(),
                const WebAboutSnippet(),
                const WebGalleryPreview(),
                const WebFeedbackSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _showScrollToTop ? 24 : -60,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'scroll_to_top',
              elevation: 6,
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward),
            ),
          ),
        ],
      ),
    );
  }
}
