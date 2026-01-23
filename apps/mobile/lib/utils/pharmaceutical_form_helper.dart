// pharmaceutical_form_helper.dart
// Helper do mapowania postaci farmaceutycznej na ikonę i jednostkę
// Źródło danych: pole pharmaceuticalFormName z API RPL (eZdrowie)

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/medicine.dart';

/// Helper do mapowania postaci farmaceutycznej na ikonę i jednostkę opakowania
class PharmaceuticalFormHelper {
  /// Zwraca ikonę Lucide dla postaci farmaceutycznej
  /// Priorytet: pattern matching na tekst postaci
  static IconData getIcon(String? form) {
    if (form == null || form.isEmpty) {
      return LucideIcons.pill; // default
    }

    final normalized = form.toLowerCase();

    // Tabletki (najczęstsze)
    if (normalized.contains('tabletk')) {
      return LucideIcons.tablets;
    }

    // Iniekcje (roztwory do wstrzykiwań, ampułki)
    if (normalized.contains('wstrzykiw') ||
        normalized.contains('ampułk') ||
        normalized.contains('iniekcj') ||
        normalized.contains('ampułkostrzykawk')) {
      return LucideIcons.syringe;
    }

    // Aerozole i inhalatory
    if (normalized.contains('aerozol') ||
        normalized.contains('inhalat') ||
        normalized.contains('spray') ||
        normalized.contains('nebuliz')) {
      return LucideIcons.sprayCan;
    }

    // Plastry transdermalne
    if (normalized.contains('plaster') ||
        normalized.contains('transder') ||
        normalized.contains('system leczniczy')) {
      return LucideIcons.sticker;
    }

    // Półstałe (maści, kremy, żele)
    if (normalized.contains('maść') ||
        normalized.contains('krem') ||
        normalized.contains('żel') ||
        normalized.contains('pasta')) {
      return LucideIcons.droplet;
    }

    // Płynne (syropy, roztwory, krople, zawiesiny)
    if (normalized.contains('syrop') ||
        normalized.contains('krople') ||
        normalized.contains('zawiesina') ||
        normalized.contains('emulsja') ||
        (normalized.contains('roztwór') && !normalized.contains('wstrzykiw'))) {
      return LucideIcons.flaskConical;
    }

    // Saszetki
    if (normalized.contains('saszetk')) {
      return LucideIcons.package;
    }

    // Stałe - kapsułki, granulaty, proszki, czopki (default dla stałych)
    if (normalized.contains('kapsułk') ||
        normalized.contains('granul') ||
        normalized.contains('proszek') ||
        normalized.contains('czopek')) {
      return LucideIcons.pill;
    }

    // Default
    return LucideIcons.pill;
  }

  /// Zwraca jednostkę opakowania dla postaci farmaceutycznej
  static PackageUnit getPackageUnit(String? form) {
    if (form == null || form.isEmpty) {
      return PackageUnit.pieces; // default
    }

    final normalized = form.toLowerCase();

    // Półstałe → gramy
    if (normalized.contains('maść') ||
        normalized.contains('krem') ||
        normalized.contains('żel') ||
        normalized.contains('pasta')) {
      return PackageUnit.grams;
    }

    // Płynne → ml
    if (normalized.contains('syrop') ||
        normalized.contains('krople') ||
        normalized.contains('zawiesina') ||
        normalized.contains('emulsja') ||
        normalized.contains('roztwór') ||
        normalized.contains('wstrzykiw') ||
        normalized.contains('ampułk') ||
        normalized.contains('iniekcj') ||
        normalized.contains('aerozol') ||
        normalized.contains('inhalat') ||
        normalized.contains('spray') ||
        normalized.contains('nebuliz')) {
      return PackageUnit.ml;
    }

    // Saszetki
    if (normalized.contains('saszetk')) {
      return PackageUnit.sachets;
    }

    // Stałe (tabletki, kapsułki, itd.) → sztuki
    return PackageUnit.pieces;
  }

  /// Zwraca etykietę jednostki dla postaci farmaceutycznej
  static String getUnitLabel(String? form) {
    final unit = getPackageUnit(form);
    switch (unit) {
      case PackageUnit.pieces:
        return 'szt.';
      case PackageUnit.ml:
        return 'ml';
      case PackageUnit.grams:
        return 'g';
      case PackageUnit.sachets:
        return 'sasz.';
      case PackageUnit.none:
        return '';
    }
  }
}
