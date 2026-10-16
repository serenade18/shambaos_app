import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

/// Redraws everything below it when the person picks another language. Every text
/// is looked up as it is built (see tr.dart), so the new language shows once each
/// widget builds again, on every open screen, without losing where they are.
class LanguageScope extends StatefulWidget {
  final WidgetBuilder builder;
  const LanguageScope({super.key, required this.builder});

  @override
  State<LanguageScope> createState() => _LanguageScopeState();
}

class _LanguageScopeState extends State<LanguageScope> {
  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = ApiService.locale;
    ApiService.language.addListener(_relabel);
  }

  @override
  void dispose() {
    ApiService.language.removeListener(_relabel);
    super.dispose();
  }

  void _relabel() {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    // Dates and numbers too: day and month names.
    Intl.defaultLocale = ApiService.locale;
    setState(() {});
    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
