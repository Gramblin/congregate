import 'package:cached_network_image/cached_network_image.dart';
import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/ads/domain/ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

class AdDetailsScreen extends StatelessWidget {
  const AdDetailsScreen({required this.ad, super.key});
  final Ad ad;

  Future<void> _openLink() async {
    final url = ad.linkUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ad.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: ad.bannerImageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: Colors.black12),
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Colors.black12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  gapH16,
                  HtmlWidget(ad.htmlContent),
                  if (ad.linkUrl != null && ad.linkUrl!.isNotEmpty) ...[
                    gapH24,
                    FilledButton.icon(
                      onPressed: _openLink,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Learn more'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
