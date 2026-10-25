import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_ui.dart';
import '../../l10n/tr.dart';

/// A country someone signs in from. Kenya signs in with phone + SMS code; every
/// other country with a username or email and a password.
class Country {
  final String iso;
  final String name;
  final String dialCode;

  const Country({required this.iso, required this.name, required this.dialCode});

  bool get signsInBySms => iso == 'KE';

  /// The flag, from the two regional indicator letters of the ISO code.
  String get flag => String.fromCharCodes(iso.codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  String get dialLabel => '$iso $dialCode';

  /// A number typed here in E.164 (+2547...). A leading 0 is the trunk prefix.
  String e164(String raw) {
    final n = raw.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (n.startsWith('+')) return n;
    return dialCode + (n.startsWith('0') ? n.substring(1) : n);
  }
}

// Kenya first, then every other country A to Z.
List<Country> get countries => [
  Country(iso: 'KE', name: 'Kenya'.tr, dialCode: '+254'),
  Country(iso: 'AF', name: 'Afghanistan'.tr, dialCode: '+93'),
  Country(iso: 'AL', name: 'Albania'.tr, dialCode: '+355'),
  Country(iso: 'DZ', name: 'Algeria'.tr, dialCode: '+213'),
  Country(iso: 'AD', name: 'Andorra'.tr, dialCode: '+376'),
  Country(iso: 'AO', name: 'Angola'.tr, dialCode: '+244'),
  Country(iso: 'AG', name: 'Antigua and Barbuda'.tr, dialCode: '+1'),
  Country(iso: 'AR', name: 'Argentina'.tr, dialCode: '+54'),
  Country(iso: 'AM', name: 'Armenia'.tr, dialCode: '+374'),
  Country(iso: 'AU', name: 'Australia'.tr, dialCode: '+61'),
  Country(iso: 'AT', name: 'Austria'.tr, dialCode: '+43'),
  Country(iso: 'AZ', name: 'Azerbaijan'.tr, dialCode: '+994'),
  Country(iso: 'BS', name: 'Bahamas'.tr, dialCode: '+1'),
  Country(iso: 'BH', name: 'Bahrain'.tr, dialCode: '+973'),
  Country(iso: 'BD', name: 'Bangladesh'.tr, dialCode: '+880'),
  Country(iso: 'BB', name: 'Barbados'.tr, dialCode: '+1'),
  Country(iso: 'BY', name: 'Belarus'.tr, dialCode: '+375'),
  Country(iso: 'BE', name: 'Belgium'.tr, dialCode: '+32'),
  Country(iso: 'BZ', name: 'Belize'.tr, dialCode: '+501'),
  Country(iso: 'BJ', name: 'Benin'.tr, dialCode: '+229'),
  Country(iso: 'BT', name: 'Bhutan'.tr, dialCode: '+975'),
  Country(iso: 'BO', name: 'Bolivia'.tr, dialCode: '+591'),
  Country(iso: 'BA', name: 'Bosnia and Herzegovina'.tr, dialCode: '+387'),
  Country(iso: 'BW', name: 'Botswana'.tr, dialCode: '+267'),
  Country(iso: 'BR', name: 'Brazil'.tr, dialCode: '+55'),
  Country(iso: 'BN', name: 'Brunei'.tr, dialCode: '+673'),
  Country(iso: 'BG', name: 'Bulgaria'.tr, dialCode: '+359'),
  Country(iso: 'BF', name: 'Burkina Faso'.tr, dialCode: '+226'),
  Country(iso: 'BI', name: 'Burundi'.tr, dialCode: '+257'),
  Country(iso: 'KH', name: 'Cambodia'.tr, dialCode: '+855'),
  Country(iso: 'CM', name: 'Cameroon'.tr, dialCode: '+237'),
  Country(iso: 'CA', name: 'Canada'.tr, dialCode: '+1'),
  Country(iso: 'CV', name: 'Cape Verde'.tr, dialCode: '+238'),
  Country(iso: 'CF', name: 'Central African Republic'.tr, dialCode: '+236'),
  Country(iso: 'TD', name: 'Chad'.tr, dialCode: '+235'),
  Country(iso: 'CL', name: 'Chile'.tr, dialCode: '+56'),
  Country(iso: 'CN', name: 'China'.tr, dialCode: '+86'),
  Country(iso: 'CO', name: 'Colombia'.tr, dialCode: '+57'),
  Country(iso: 'KM', name: 'Comoros'.tr, dialCode: '+269'),
  Country(iso: 'CG', name: 'Congo'.tr, dialCode: '+242'),
  Country(iso: 'CR', name: 'Costa Rica'.tr, dialCode: '+506'),
  Country(iso: 'CI', name: "Côte d'Ivoire".tr, dialCode: '+225'),
  Country(iso: 'HR', name: 'Croatia'.tr, dialCode: '+385'),
  Country(iso: 'CU', name: 'Cuba'.tr, dialCode: '+53'),
  Country(iso: 'CY', name: 'Cyprus'.tr, dialCode: '+357'),
  Country(iso: 'CZ', name: 'Czechia'.tr, dialCode: '+420'),
  Country(iso: 'CD', name: 'DR Congo'.tr, dialCode: '+243'),
  Country(iso: 'DK', name: 'Denmark'.tr, dialCode: '+45'),
  Country(iso: 'DJ', name: 'Djibouti'.tr, dialCode: '+253'),
  Country(iso: 'DM', name: 'Dominica'.tr, dialCode: '+1'),
  Country(iso: 'DO', name: 'Dominican Republic'.tr, dialCode: '+1'),
  Country(iso: 'EC', name: 'Ecuador'.tr, dialCode: '+593'),
  Country(iso: 'EG', name: 'Egypt'.tr, dialCode: '+20'),
  Country(iso: 'SV', name: 'El Salvador'.tr, dialCode: '+503'),
  Country(iso: 'GQ', name: 'Equatorial Guinea'.tr, dialCode: '+240'),
  Country(iso: 'ER', name: 'Eritrea'.tr, dialCode: '+291'),
  Country(iso: 'EE', name: 'Estonia'.tr, dialCode: '+372'),
  Country(iso: 'SZ', name: 'Eswatini'.tr, dialCode: '+268'),
  Country(iso: 'ET', name: 'Ethiopia'.tr, dialCode: '+251'),
  Country(iso: 'FJ', name: 'Fiji'.tr, dialCode: '+679'),
  Country(iso: 'FI', name: 'Finland'.tr, dialCode: '+358'),
  Country(iso: 'FR', name: 'France'.tr, dialCode: '+33'),
  Country(iso: 'GA', name: 'Gabon'.tr, dialCode: '+241'),
  Country(iso: 'GM', name: 'Gambia'.tr, dialCode: '+220'),
  Country(iso: 'GE', name: 'Georgia'.tr, dialCode: '+995'),
  Country(iso: 'DE', name: 'Germany'.tr, dialCode: '+49'),
  Country(iso: 'GH', name: 'Ghana'.tr, dialCode: '+233'),
  Country(iso: 'GR', name: 'Greece'.tr, dialCode: '+30'),
  Country(iso: 'GD', name: 'Grenada'.tr, dialCode: '+1'),
  Country(iso: 'GT', name: 'Guatemala'.tr, dialCode: '+502'),
  Country(iso: 'GN', name: 'Guinea'.tr, dialCode: '+224'),
  Country(iso: 'GW', name: 'Guinea-Bissau'.tr, dialCode: '+245'),
  Country(iso: 'GY', name: 'Guyana'.tr, dialCode: '+592'),
  Country(iso: 'HT', name: 'Haiti'.tr, dialCode: '+509'),
  Country(iso: 'HN', name: 'Honduras'.tr, dialCode: '+504'),
  Country(iso: 'HU', name: 'Hungary'.tr, dialCode: '+36'),
  Country(iso: 'IS', name: 'Iceland'.tr, dialCode: '+354'),
  Country(iso: 'IN', name: 'India'.tr, dialCode: '+91'),
  Country(iso: 'ID', name: 'Indonesia'.tr, dialCode: '+62'),
  Country(iso: 'IR', name: 'Iran'.tr, dialCode: '+98'),
  Country(iso: 'IQ', name: 'Iraq'.tr, dialCode: '+964'),
  Country(iso: 'IE', name: 'Ireland'.tr, dialCode: '+353'),
  Country(iso: 'IL', name: 'Israel'.tr, dialCode: '+972'),
  Country(iso: 'IT', name: 'Italy'.tr, dialCode: '+39'),
  Country(iso: 'JM', name: 'Jamaica'.tr, dialCode: '+1'),
  Country(iso: 'JP', name: 'Japan'.tr, dialCode: '+81'),
  Country(iso: 'JO', name: 'Jordan'.tr, dialCode: '+962'),
  Country(iso: 'KZ', name: 'Kazakhstan'.tr, dialCode: '+7'),
  Country(iso: 'KI', name: 'Kiribati'.tr, dialCode: '+686'),
  Country(iso: 'XK', name: 'Kosovo'.tr, dialCode: '+383'),
  Country(iso: 'KW', name: 'Kuwait'.tr, dialCode: '+965'),
  Country(iso: 'KG', name: 'Kyrgyzstan'.tr, dialCode: '+996'),
  Country(iso: 'LA', name: 'Laos'.tr, dialCode: '+856'),
  Country(iso: 'LV', name: 'Latvia'.tr, dialCode: '+371'),
  Country(iso: 'LB', name: 'Lebanon'.tr, dialCode: '+961'),
  Country(iso: 'LS', name: 'Lesotho'.tr, dialCode: '+266'),
  Country(iso: 'LR', name: 'Liberia'.tr, dialCode: '+231'),
  Country(iso: 'LY', name: 'Libya'.tr, dialCode: '+218'),
  Country(iso: 'LI', name: 'Liechtenstein'.tr, dialCode: '+423'),
  Country(iso: 'LT', name: 'Lithuania'.tr, dialCode: '+370'),
  Country(iso: 'LU', name: 'Luxembourg'.tr, dialCode: '+352'),
  Country(iso: 'MG', name: 'Madagascar'.tr, dialCode: '+261'),
  Country(iso: 'MW', name: 'Malawi'.tr, dialCode: '+265'),
  Country(iso: 'MY', name: 'Malaysia'.tr, dialCode: '+60'),
  Country(iso: 'MV', name: 'Maldives'.tr, dialCode: '+960'),
  Country(iso: 'ML', name: 'Mali'.tr, dialCode: '+223'),
  Country(iso: 'MT', name: 'Malta'.tr, dialCode: '+356'),
  Country(iso: 'MH', name: 'Marshall Islands'.tr, dialCode: '+692'),
  Country(iso: 'MR', name: 'Mauritania'.tr, dialCode: '+222'),
  Country(iso: 'MU', name: 'Mauritius'.tr, dialCode: '+230'),
  Country(iso: 'MX', name: 'Mexico'.tr, dialCode: '+52'),
  Country(iso: 'FM', name: 'Micronesia'.tr, dialCode: '+691'),
  Country(iso: 'MD', name: 'Moldova'.tr, dialCode: '+373'),
  Country(iso: 'MC', name: 'Monaco'.tr, dialCode: '+377'),
  Country(iso: 'MN', name: 'Mongolia'.tr, dialCode: '+976'),
  Country(iso: 'ME', name: 'Montenegro'.tr, dialCode: '+382'),
  Country(iso: 'MA', name: 'Morocco'.tr, dialCode: '+212'),
  Country(iso: 'MZ', name: 'Mozambique'.tr, dialCode: '+258'),
  Country(iso: 'MM', name: 'Myanmar'.tr, dialCode: '+95'),
  Country(iso: 'NA', name: 'Namibia'.tr, dialCode: '+264'),
  Country(iso: 'NR', name: 'Nauru'.tr, dialCode: '+674'),
  Country(iso: 'NP', name: 'Nepal'.tr, dialCode: '+977'),
  Country(iso: 'NL', name: 'Netherlands'.tr, dialCode: '+31'),
  Country(iso: 'NZ', name: 'New Zealand'.tr, dialCode: '+64'),
  Country(iso: 'NI', name: 'Nicaragua'.tr, dialCode: '+505'),
  Country(iso: 'NE', name: 'Niger'.tr, dialCode: '+227'),
  Country(iso: 'NG', name: 'Nigeria'.tr, dialCode: '+234'),
  Country(iso: 'KP', name: 'North Korea'.tr, dialCode: '+850'),
  Country(iso: 'MK', name: 'North Macedonia'.tr, dialCode: '+389'),
  Country(iso: 'NO', name: 'Norway'.tr, dialCode: '+47'),
  Country(iso: 'OM', name: 'Oman'.tr, dialCode: '+968'),
  Country(iso: 'PK', name: 'Pakistan'.tr, dialCode: '+92'),
  Country(iso: 'PW', name: 'Palau'.tr, dialCode: '+680'),
  Country(iso: 'PS', name: 'Palestine'.tr, dialCode: '+970'),
  Country(iso: 'PA', name: 'Panama'.tr, dialCode: '+507'),
  Country(iso: 'PG', name: 'Papua New Guinea'.tr, dialCode: '+675'),
  Country(iso: 'PY', name: 'Paraguay'.tr, dialCode: '+595'),
  Country(iso: 'PE', name: 'Peru'.tr, dialCode: '+51'),
  Country(iso: 'PH', name: 'Philippines'.tr, dialCode: '+63'),
  Country(iso: 'PL', name: 'Poland'.tr, dialCode: '+48'),
  Country(iso: 'PT', name: 'Portugal'.tr, dialCode: '+351'),
  Country(iso: 'QA', name: 'Qatar'.tr, dialCode: '+974'),
  Country(iso: 'RO', name: 'Romania'.tr, dialCode: '+40'),
  Country(iso: 'RU', name: 'Russia'.tr, dialCode: '+7'),
  Country(iso: 'RW', name: 'Rwanda'.tr, dialCode: '+250'),
  Country(iso: 'KN', name: 'Saint Kitts and Nevis'.tr, dialCode: '+1'),
  Country(iso: 'LC', name: 'Saint Lucia'.tr, dialCode: '+1'),
  Country(iso: 'VC', name: 'Saint Vincent and the Grenadines'.tr, dialCode: '+1'),
  Country(iso: 'WS', name: 'Samoa'.tr, dialCode: '+685'),
  Country(iso: 'SM', name: 'San Marino'.tr, dialCode: '+378'),
  Country(iso: 'ST', name: 'São Tomé and Príncipe'.tr, dialCode: '+239'),
  Country(iso: 'SA', name: 'Saudi Arabia'.tr, dialCode: '+966'),
  Country(iso: 'SN', name: 'Senegal'.tr, dialCode: '+221'),
  Country(iso: 'RS', name: 'Serbia'.tr, dialCode: '+381'),
  Country(iso: 'SC', name: 'Seychelles'.tr, dialCode: '+248'),
  Country(iso: 'SL', name: 'Sierra Leone'.tr, dialCode: '+232'),
  Country(iso: 'SG', name: 'Singapore'.tr, dialCode: '+65'),
  Country(iso: 'SK', name: 'Slovakia'.tr, dialCode: '+421'),
  Country(iso: 'SI', name: 'Slovenia'.tr, dialCode: '+386'),
  Country(iso: 'SB', name: 'Solomon Islands'.tr, dialCode: '+677'),
  Country(iso: 'SO', name: 'Somalia'.tr, dialCode: '+252'),
  Country(iso: 'ZA', name: 'South Africa'.tr, dialCode: '+27'),
  Country(iso: 'KR', name: 'South Korea'.tr, dialCode: '+82'),
  Country(iso: 'SS', name: 'South Sudan'.tr, dialCode: '+211'),
  Country(iso: 'ES', name: 'Spain'.tr, dialCode: '+34'),
  Country(iso: 'LK', name: 'Sri Lanka'.tr, dialCode: '+94'),
  Country(iso: 'SD', name: 'Sudan'.tr, dialCode: '+249'),
  Country(iso: 'SR', name: 'Suriname'.tr, dialCode: '+597'),
  Country(iso: 'SE', name: 'Sweden'.tr, dialCode: '+46'),
  Country(iso: 'CH', name: 'Switzerland'.tr, dialCode: '+41'),
  Country(iso: 'SY', name: 'Syria'.tr, dialCode: '+963'),
  Country(iso: 'TW', name: 'Taiwan'.tr, dialCode: '+886'),
  Country(iso: 'TJ', name: 'Tajikistan'.tr, dialCode: '+992'),
  Country(iso: 'TZ', name: 'Tanzania'.tr, dialCode: '+255'),
  Country(iso: 'TH', name: 'Thailand'.tr, dialCode: '+66'),
  Country(iso: 'TL', name: 'Timor-Leste'.tr, dialCode: '+670'),
  Country(iso: 'TG', name: 'Togo'.tr, dialCode: '+228'),
  Country(iso: 'TO', name: 'Tonga'.tr, dialCode: '+676'),
  Country(iso: 'TT', name: 'Trinidad and Tobago'.tr, dialCode: '+1'),
  Country(iso: 'TN', name: 'Tunisia'.tr, dialCode: '+216'),
  Country(iso: 'TR', name: 'Turkey'.tr, dialCode: '+90'),
  Country(iso: 'TM', name: 'Turkmenistan'.tr, dialCode: '+993'),
  Country(iso: 'TV', name: 'Tuvalu'.tr, dialCode: '+688'),
  Country(iso: 'UG', name: 'Uganda'.tr, dialCode: '+256'),
  Country(iso: 'UA', name: 'Ukraine'.tr, dialCode: '+380'),
  Country(iso: 'AE', name: 'United Arab Emirates'.tr, dialCode: '+971'),
  Country(iso: 'GB', name: 'United Kingdom'.tr, dialCode: '+44'),
  Country(iso: 'US', name: 'United States'.tr, dialCode: '+1'),
  Country(iso: 'UY', name: 'Uruguay'.tr, dialCode: '+598'),
  Country(iso: 'UZ', name: 'Uzbekistan'.tr, dialCode: '+998'),
  Country(iso: 'VU', name: 'Vanuatu'.tr, dialCode: '+678'),
  Country(iso: 'VA', name: 'Vatican City'.tr, dialCode: '+39'),
  Country(iso: 'VE', name: 'Venezuela'.tr, dialCode: '+58'),
  Country(iso: 'VN', name: 'Vietnam'.tr, dialCode: '+84'),
  Country(iso: 'YE', name: 'Yemen'.tr, dialCode: '+967'),
  Country(iso: 'ZM', name: 'Zambia'.tr, dialCode: '+260'),
  Country(iso: 'ZW', name: 'Zimbabwe'.tr, dialCode: '+263'),
];

Country countryFor(String? iso) =>
    countries.firstWhere((c) => c.iso == iso, orElse: () => countries.first);

// Where several countries share a code, the one a number is read as.
const _sharedCodes = {'+1': 'US', '+7': 'RU', '+39': 'IT'};

/// A saved number (+2347...) split into its country and the rest, as typed after
/// the code. Kenya, with the number unchanged, when no code matches.
(Country, String) splitPhone(String e164) {
  final n = e164.replaceAll(RegExp(r'[^\d+]'), '');
  if (!n.startsWith('+')) return (countries.first, n.startsWith('254') ? n.substring(3) : n);
  Country? best;
  for (final c in countries) {
    if (n.startsWith(c.dialCode) && (best == null || c.dialCode.length > best.dialCode.length)) best = c;
  }
  if (best == null) return (countries.first, n);
  final shared = _sharedCodes[best.dialCode];
  return (shared != null ? countryFor(shared) : best, n.substring(best.dialCode.length));
}

const _savedKey = 'sign_in_country';

/// The country chosen last time on this phone, else the phone's own region,
/// else Kenya.
Future<Country> initialCountry() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_savedKey);
  if (saved != null) return countryFor(saved);
  final region = WidgetsBinding.instance.platformDispatcher.locale.countryCode?.toUpperCase();
  final known = countries.any((c) => c.iso == region);
  return known ? countryFor(region) : countries.first;
}

Future<void> saveCountry(Country c) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_savedKey, c.iso);
}

/// The country list as a bottom sheet, with a search; the one picked, or null.
Future<Country?> showCountryPicker(BuildContext context, Country selected) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Ledger.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Ledger.radiusSheet))),
    builder: (_) => _CountryPicker(selected: selected),
  );
}

class _CountryPicker extends StatefulWidget {
  final Country selected;
  const _CountryPicker({required this.selected});

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final _all = countries;
  String _query = '';

  // By name in the chosen language, ISO code or dialling code.
  List<Country> get _shown {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((c) =>
        c.name.toLowerCase().contains(q) || c.iso.toLowerCase() == q || c.dialCode.contains(q.replaceAll(' ', ''))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (_, scroll) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Ledger.rule, borderRadius: BorderRadius.circular(999))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Select Country'.tr, style: Ledger.title.copyWith(fontSize: 19, height: 24 / 19))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: LedgerField(
              label: 'Search countries'.tr,
              input: TextField(
                autocorrect: false,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                style: Ledger.input,
                cursorColor: Ledger.shamba,
                decoration: Ledger.bare(''),
              ),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No country matches.'.tr, style: Ledger.body),
                  )
                : ListView.builder(
                    controller: scroll,
                    itemCount: shown.length,
                    padding: EdgeInsets.only(bottom: 12 + MediaQuery.paddingOf(context).bottom),
                    itemBuilder: (_, i) {
                      final c = shown[i];
                      return InkWell(
                        onTap: () => Navigator.pop(context, c),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: c.iso == widget.selected.iso ? Ledger.shambaTint : null,
                            border: const Border(top: BorderSide(color: Ledger.rule)),
                          ),
                          child: Row(children: [
                            Text(c.flag, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(c.name, style: Ledger.label)),
                            Text(c.dialLabel, style: Ledger.code.copyWith(fontSize: 15, color: Ledger.inkMuted)),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
