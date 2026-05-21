class WestAfricanCountry {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int maxDigits;

  const WestAfricanCountry({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.maxDigits,
  });
}

const List<WestAfricanCountry> westAfricaCountries = [
  WestAfricanCountry(name: 'Burkina Faso',     code: 'BF', dialCode: '+226', flag: '🇧🇫', maxDigits: 8),
  WestAfricanCountry(name: 'Côte d\'Ivoire',   code: 'CI', dialCode: '+225', flag: '🇨🇮', maxDigits: 10),
  WestAfricanCountry(name: 'Mali',             code: 'ML', dialCode: '+223', flag: '🇲🇱', maxDigits: 8),
  WestAfricanCountry(name: 'Niger',            code: 'NE', dialCode: '+227', flag: '🇳🇪', maxDigits: 8),
  WestAfricanCountry(name: 'Sénégal',          code: 'SN', dialCode: '+221', flag: '🇸🇳', maxDigits: 9),
  WestAfricanCountry(name: 'Togo',             code: 'TG', dialCode: '+228', flag: '🇹🇬', maxDigits: 8),
  WestAfricanCountry(name: 'Bénin',            code: 'BJ', dialCode: '+229', flag: '🇧🇯', maxDigits: 8),
  WestAfricanCountry(name: 'Guinée',           code: 'GN', dialCode: '+224', flag: '🇬🇳', maxDigits: 9),
  WestAfricanCountry(name: 'Mauritanie',       code: 'MR', dialCode: '+222', flag: '🇲🇷', maxDigits: 8),
  WestAfricanCountry(name: 'Ghana',            code: 'GH', dialCode: '+233', flag: '🇬🇭', maxDigits: 9),
  WestAfricanCountry(name: 'Nigeria',          code: 'NG', dialCode: '+234', flag: '🇳🇬', maxDigits: 10),
  WestAfricanCountry(name: 'Sierra Leone',     code: 'SL', dialCode: '+232', flag: '🇸🇱', maxDigits: 8),
  WestAfricanCountry(name: 'Liberia',          code: 'LR', dialCode: '+231', flag: '🇱🇷', maxDigits: 8),
  WestAfricanCountry(name: 'Guinée-Bissau',    code: 'GW', dialCode: '+245', flag: '🇬🇼', maxDigits: 7),
  WestAfricanCountry(name: 'Gambie',           code: 'GM', dialCode: '+220', flag: '🇬🇲', maxDigits: 7),
  WestAfricanCountry(name: 'Cap-Vert',         code: 'CV', dialCode: '+238', flag: '🇨🇻', maxDigits: 7),
];
