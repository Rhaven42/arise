import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Enregistre les licences OFL des polices embarquées (obligation de l'OFL).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, path) in const [
      ('Cinzel', 'assets/fonts/cinzel/OFL.txt'),
      ('IM Fell English', 'assets/fonts/im_fell_english/OFL.txt'),
    ]) {
      final text = await rootBundle.loadString(path);
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
}
