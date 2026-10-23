import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/sl_form.dart';
import '../auth/auth_ui.dart';
import '../records/record_form.dart';
import 'add_to_farm.dart';
import 'farm_map_screen.dart';
import '../../l10n/tr.dart';

/// Kenya's 47 counties, for the farm's place until its boundary is mapped.
const kenyaCounties = [
  'Baringo', 'Bomet', 'Bungoma', 'Busia', 'Elgeyo-Marakwet', 'Embu', 'Garissa', 'Homa Bay', 'Isiolo', 'Kajiado',
  'Kakamega', 'Kericho', 'Kiambu', 'Kilifi', 'Kirinyaga', 'Kisii', 'Kisumu', 'Kitui', 'Kwale', 'Laikipia', 'Lamu',
  'Machakos', 'Makueni', 'Mandera', 'Marsabit', 'Meru', 'Migori', 'Mombasa', "Murang'a", 'Nairobi', 'Nakuru', 'Nandi',
  'Narok', 'Nyamira', 'Nyandarua', 'Nyeri', 'Samburu', 'Siaya', 'Taita-Taveta', 'Tana River', 'Tharaka-Nithi',
  'Trans Nzoia', 'Turkana', 'Uasin Gishu', 'Vihiga', 'Wajir', 'West Pokot',
];

/// A new farm, the whole way: its name and county (screen 23b), then Map your farm
/// (screens 05–09, which can be put off), then "What are you adding?" (screen 27).
/// From sign-in, Home and My farm. True when a farm was made.
Future<bool> setUpFarm(BuildContext context) => setUpFarmWith(Navigator.of(context));

Future<bool> setUpFarmWith(NavigatorState navigator) async {
  final farm = await navigator.push<Map<String, dynamic>>(MaterialPageRoute(builder: (_) => const SetupFarmScreen()));
  if (farm == null) return false;
  await navigator.push(MaterialPageRoute(builder: (_) => FarmMapScreen(farm: farm)));
  await navigator.push(MaterialPageRoute(builder: (_) => AddToFarmScreen(farm: farm)));
  FarmMapScreen.boundarySaved.value++; // Home and My farm reload
  return true;
}

/// Screen 23b, "Set up your farm": its name and county (POST /farms). Closes with the farm.
class SetupFarmScreen extends StatefulWidget {
  const SetupFarmScreen({super.key});

  @override
  State<SetupFarmScreen> createState() => _SetupFarmScreenState();
}

class _SetupFarmScreenState extends State<SetupFarmScreen> with RecordForm {
  static const _pin = '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0"/><circle cx="12" cy="10" r="3"/>';
  static const _map =
      '<path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z"/><path d="M15 5.764v15"/><path d="M9 3.236v15"/>';

  final _name = TextEditingController();
  String? _county;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCounty() async {
    final c = context.appColors;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheet) => SizedBox(
        height: MediaQuery.sizeOf(sheet).height * 0.75,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('County'.tr,
                style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
              for (final county in kenyaCounties)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(county, style: TextStyle(fontFamily: AppType.text, fontSize: 16, color: c.textPrimary)),
                  trailing: county == _county ? Icon(Icons.check_rounded, color: c.brandText) : null,
                  onTap: () => Navigator.pop(sheet, county),
                ),
            ]),
          ),
        ]),
      ),
    );
    if (picked != null) {
      setState(() {
        _county = picked;
        fieldErrors.remove('county');
      });
    }
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return fail("Enter the farm's name.".tr, 'name');
    if (_county == null) return fail('Choose the county.'.tr, 'county');
    save(() => ApiService.post('/farms', {'name': name, 'county': _county}), '',
        next: (res) => Navigator.pop(context, Map<String, dynamic>.from(res.data as Map)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SlFormPage(
      eyebrow: 'NEW FARM · STEP 1 OF 3'.tr,
      title: 'Set up your farm'.tr,
      saving: saving,
      error: banner({'name', 'county'}),
      saveLabel: 'Next: map your farm'.tr,
      onSave: _save,
      children: [
        Row(children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(color: i == 0 ? c.shamba : c.divider, borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ],
        ]),
        SlField(
          label: 'Farm name'.tr,
          required: true,
          hint: 'What you and your workers call it.'.tr,
          error: err('name'),
          child: SlTextBox(controller: _name, placeholder: 'Wanjiku Farm', caps: TextCapitalization.words, error: err('name') != null),
        ),
        SlField(
          label: 'County'.tr,
          required: true,
          hint: 'Weather and alerts use the county until the farm is mapped.'.tr,
          error: err('county'),
          child: SlSelectBox(
            icon: _pin,
            text: _county ?? 'Choose the county'.tr,
            muted: _county == null,
            error: err('county') != null,
            onTap: _pickCounty,
          ),
        ),
        SlCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
              child: Center(child: LineIcon(_map, size: 20, color: c.brandText)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Next, map your farm'.tr,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                const SizedBox(height: 2),
                Text("Walk or draw its boundary, or do it later. Then choose what you're running.".tr,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, color: c.textSecondary)),
              ]),
            ),
          ]),
        ),
      ],
    );
  }
}
