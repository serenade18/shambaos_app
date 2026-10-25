import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';
import '../../l10n/tr.dart';
import '../../widgets/skeleton.dart';

/// The Shamba OS website. Override per build:
///   flutter run --dart-define=SITE_URL=https://staging.shambaos.com
const siteUrl = String.fromEnvironment('SITE_URL', defaultValue: 'https://shambaos.com');

/// A page from the website inside the app: the privacy policy, the terms.
class WebPageScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebPageScreen({super.key, required this.title, required this.url});

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  late final WebViewController _web;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => mounted ? setState(() => _loading = false) : null,
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) setState(() => _failed = true);
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(children: [
              Semantics(
                button: true,
                label: 'Back'.tr,
                excludeSemantics: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.cardBackground,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: SizedBox(width: 44, height: 44, child: Icon(PhosphorIconsRegular.arrowLeft, size: 22, color: c.textPrimary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.title,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
              ),
            ]),
          ),
          Expanded(
            child: _failed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Could not open this page. Check your connection and try again.'.tr,
                          textAlign: TextAlign.center, style: AppType.body.copyWith(color: c.textSecondary)),
                    ),
                  )
                : Stack(children: [
                    WebViewWidget(controller: _web),
                    if (_loading)
                      Positioned.fill(
                        child: ColoredBox(
                          color: c.scaffoldBackground,
                          child: const SingleChildScrollView(padding: EdgeInsets.all(20), child: SkeletonText()),
                        ),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }
}
