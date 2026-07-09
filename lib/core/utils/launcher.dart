import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the platform browser / external app.
Future<void> openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}

/// Shares a link with the native share sheet (clipboard fallback on desktop).
Future<void> shareLink(String title, String url) =>
    Share.share('$title\n$url', subject: title);
