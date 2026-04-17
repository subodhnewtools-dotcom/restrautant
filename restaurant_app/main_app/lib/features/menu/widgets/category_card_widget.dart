import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/theme/app_theme.dart';

class CategoryCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final bool isVeg;
  final VoidCallback onTap;

  const CategoryCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.isVeg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Background Image or Gradient
            if (imageUrl != null && imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppTheme.kPrimaryColor.withOpacity(0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.kPrimaryColor.withOpacity(0.1),
                  child: const Icon(Icons.restaurant, size: 40, color: AppTheme.kTextSecondary),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.kPrimaryColor.withOpacity(0.2),
                      AppTheme.kPrimaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
              ),

            // Overlay gradient for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Veg/Non-Veg Indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isVeg ? const Color(0xFF43A047) : const Color(0xFFE53935),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isVeg ? Icons.circle : Icons.remove,
                  size: 12,
                  color: isVeg ? const Color(0xFF43A047) : const Color(0xFFE53935),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
