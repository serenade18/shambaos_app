import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';

/// Your profile photo (GET/POST/DELETE /me/photo), loaded once and shared by
/// every screen that shows it, so a new photo shows everywhere at once.
class MyPhoto {
  MyPhoto._();

  static final ValueNotifier<Uint8List?> bytes = ValueNotifier(null);
  static bool _asked = false;

  /// Loads the photo the first time a screen needs it.
  static void ensure() {
    if (_asked) return;
    _asked = true;
    refresh();
  }

  static Future<void> refresh() async => bytes.value = await ApiService.getBytes('/me/photo');

  /// Sends a photo; the server crops it square. On success the shared copy updates.
  static Future<ApiResponse> upload(List<int> data, String filename) async {
    final res = await ApiService.postFile('/me/photo', field: 'photo', bytes: data, filename: filename);
    if (!res.error) await refresh();
    return res;
  }

  static Future<ApiResponse> remove() async {
    final res = await ApiService.delete('/me/photo');
    if (!res.error) bytes.value = null;
    return res;
  }

  /// On sign-out: the next person's photo is theirs.
  static void clear() {
    _asked = false;
    bytes.value = null;
  }
}

/// A round avatar: your photo, or your initials on the green well.
class MyAvatar extends StatefulWidget {
  final String initials;
  final double size;

  const MyAvatar({super.key, required this.initials, this.size = 44});

  @override
  State<MyAvatar> createState() => _MyAvatarState();
}

class _MyAvatarState extends State<MyAvatar> {
  @override
  void initState() {
    super.initState();
    MyPhoto.ensure();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: MyPhoto.bytes,
      builder: (context, photo, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.brandSoft),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: photo != null
            ? Image.memory(photo, width: widget.size, height: widget.size, fit: BoxFit.cover, gaplessPlayback: true)
            : Text(widget.initials,
                style: TextStyle(
                    fontFamily: AppType.text, fontSize: widget.size * 0.34, fontWeight: FontWeight.w700, color: c.brandText)),
      ),
    );
  }
}
