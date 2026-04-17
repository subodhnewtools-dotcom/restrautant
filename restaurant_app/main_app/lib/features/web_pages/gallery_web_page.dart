import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/cms_repository.dart';
import '../../shared/utils/app_localizations.dart';

class GalleryWebPage extends ConsumerWidget {
  const GalleryWebPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final cmsState = ref.watch(cmsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.t('gallery') ?? 'Gallery'),
      ),
      body: cmsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cmsState.error != null
              ? Center(child: Text('Error: ${cmsState.error}'))
              : _buildGallery(context, ref),
    );
  }

  Widget _buildGallery(BuildContext context, WidgetRef ref) {
    // Get gallery images from CMS
    final galleryData = ref.read(cmsProvider).sections?['gallery'];
    
    if (galleryData == null || galleryData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No images available',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: galleryData.length,
      itemBuilder: (context, index) {
        final imageUrl = galleryData[index]['image_url'] as String?;
        return GestureDetector(
          onTap: () => _showLightbox(context, galleryData, index),
          child: Hero(
            tag: 'gallery_$index',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey[500]),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLightbox(BuildContext context, List<dynamic> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                final imageUrl = images[index]['image_url'] as String?;
                return InteractiveViewer(
                  child: Image.network(
                    imageUrl ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image, size: 64, color: Colors.white);
                    },
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (initialIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 48),
                    onPressed: () {
                      // Navigate to previous image
                    },
                  ),
                ),
              ),
            if (initialIndex < images.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 48),
                    onPressed: () {
                      // Navigate to next image
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
