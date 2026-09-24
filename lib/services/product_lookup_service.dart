import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';

class ScannedProduct {
  final String? name;
  final String? brand;
  final String? rawQuantity;

  /// Multi-pack count parsed from the quantity string (e.g. 6 for "6 x 330 ml").
  final int? quantity;

  /// Package format parsed from the quantity string (e.g. 330 + "ml").
  final double? formatValue;
  final String? formatUnit;

  ScannedProduct({
    this.name,
    this.brand,
    this.rawQuantity,
    this.quantity,
    this.formatValue,
    this.formatUnit,
  });
}

enum ProductLookupStatus { found, notFound, error }

class ProductLookupResult {
  final ProductLookupStatus status;
  final ScannedProduct? product;

  /// True when the product was found in Open Food Facts (food database).
  final bool isFood;

  const ProductLookupResult._(this.status, this.product, {this.isFood = false});

  const ProductLookupResult.found(ScannedProduct product, {bool isFood = false})
      : this._(ProductLookupStatus.found, product, isFood: isFood);

  const ProductLookupResult.notFound()
      : this._(ProductLookupStatus.notFound, null);

  const ProductLookupResult.error()
      : this._(ProductLookupStatus.error, null);
}

class ProductLookupService {
  static const String _opfBaseUrl = 'https://world.openproductsfacts.org/api/v2/product';
  static const String _offBaseUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const String _fields = 'code,product_name,brands,quantity';
  static const Duration _timeout = Duration(seconds: 12);
  static const Duration _retryDelay = Duration(milliseconds: 400);

  /// Lookup barcode across two databases:
  /// 1. Open Products Facts (general products, household items)
  /// 2. Open Food Facts (food, fallback)
  ///
  /// Returns [ProductLookupStatus.notFound] only when both databases answered
  /// that the product is absent; if a database could not be reached the result
  /// is [ProductLookupStatus.error].
  static Future<ProductLookupResult> lookupBarcode(String barcode) async {
    final userAgent = await _userAgent();

    // Try Open Products Facts first (household products)
    final opfResult = await _lookup(
      '$_opfBaseUrl/$barcode.json?fields=$_fields',
      userAgent: userAgent,
    );
    if (opfResult.status == ProductLookupStatus.found) return opfResult;

    // Fallback to Open Food Facts (food)
    final offResult = await _lookup(
      '$_offBaseUrl/$barcode.json?fields=$_fields',
      userAgent: userAgent,
    );
    if (offResult.status == ProductLookupStatus.found) {
      return ProductLookupResult.found(offResult.product!, isFood: true);
    }

    // A network problem must not be reported as a missing product.
    if (opfResult.status == ProductLookupStatus.error ||
        offResult.status == ProductLookupStatus.error) {
      return const ProductLookupResult.error();
    }
    return const ProductLookupResult.notFound();
  }

  static Future<String> _userAgent() async {
    final repoUrl =
        'https://github.com/${AppConfig.githubOwner}/${AppConfig.githubRepo}';
    try {
      final info = await PackageInfo.fromPlatform();
      return 'HomeInventoryApp/${info.version} ($repoUrl)';
    } catch (_) {
      return 'HomeInventoryApp ($repoUrl)';
    }
  }

  static Future<ProductLookupResult> _lookup(
    String url, {
    required String userAgent,
  }) async {
    final firstAttempt = await _request(url, userAgent: userAgent);
    if (firstAttempt.status != ProductLookupStatus.error) return firstAttempt;

    await Future.delayed(_retryDelay);
    return _request(url, userAgent: userAgent);
  }

  static Future<ProductLookupResult> _request(
    String url, {
    required String userAgent,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': userAgent,
        },
      ).timeout(_timeout);

      if (response.statusCode == 404) {
        return const ProductLookupResult.notFound();
      }
      if (response.statusCode != 200) {
        return const ProductLookupResult.error();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Both APIs return { status, product: { ... } }
      final product = data['product'];
      if (data['status'] == 0 || product is! Map) {
        return const ProductLookupResult.notFound();
      }

      final rawName = product['product_name'] as String?;
      final rawBrands = product['brands'] as String?;
      final rawQuantity = product['quantity'] as String?;

      // Clean up brands: take only the first one
      final brand = _extractFirstBrand(rawBrands);

      // Parse the package format: number + unit (e.g. "600 g", "1.5 l")
      final parsed = _parseQuantityAndFormat(rawQuantity);

      return ProductLookupResult.found(ScannedProduct(
        name: rawName,
        brand: brand,
        rawQuantity: rawQuantity,
        quantity: parsed.count,
        formatValue: parsed.value,
        formatUnit: parsed.unit,
      ));
    } catch (e) {
      return const ProductLookupResult.error();
    }
  }

  static String? _extractFirstBrand(String? brands) {
    if (brands == null || brands.isEmpty) return null;
    // APIs return comma-separated brands: "Nutella,Ferrero"
    return brands.split(',').first.trim();
  }

  static ({int? count, double? value, String? unit}) _parseQuantityAndFormat(
    String? quantityStr,
  ) {
    if (quantityStr == null || quantityStr.isEmpty) {
      return (count: null, value: null, unit: null);
    }

    final matches = RegExp(r'(\d+(?:[.,]\d+)?)\s*([a-zA-Z]+)')
        .allMatches(quantityStr)
        .map((match) {
          final number = double.tryParse(match.group(1)!.replaceAll(',', '.'));
          final unit = _normalizeUnit(match.group(2)!);
          return (number: number, unit: unit);
        })
        .where((pair) => pair.number != null && pair.unit != null)
        .toList();

    if (matches.isEmpty) return (count: null, value: null, unit: null);

    final isMultiPack =
        RegExp(r'\d\s*[x×]\s*\d', caseSensitive: false).hasMatch(quantityStr);

    if (isMultiPack && matches.length >= 2) {
      final count = matches.first.number!.round();
      final last = matches.last;
      return (count: count > 0 ? count : null, value: last.number, unit: last.unit);
    }

    final last = matches.last;
    return (count: null, value: last.number, unit: last.unit);
  }

  static String? _normalizeUnit(String raw) {
    switch (raw.toLowerCase()) {
      case 'g':
      case 'gr':
      case 'grammi':
      case 'grammo':
        return 'g';
      case 'kg':
      case 'chilogrammi':
      case 'chilo':
      case 'chili':
        return 'kg';
      case 'ml':
      case 'millilitri':
        return 'ml';
      case 'cl':
      case 'centilitri':
        return 'cl';
      case 'l':
      case 'lt':
      case 'litri':
      case 'litro':
        return 'l';
      case 'pz':
      case 'pezzi':
      case 'pezzo':
        return 'pz';
      default:
        return null;
    }
  }
}
