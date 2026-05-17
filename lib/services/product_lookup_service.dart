import 'dart:convert';
import 'package:http/http.dart' as http;

class ScannedProduct {
  final String? name;
  final String? brand;
  final int? quantity;
  final String? rawQuantity;

  ScannedProduct({this.name, this.brand, this.quantity, this.rawQuantity});
}

class ProductLookupService {
  static const String _opfBaseUrl = 'https://world.openproductsfacts.org/api/v0/product';
  static const String _offBaseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  /// Lookup barcode across two databases:
  /// 1. Open Products Facts (general products, household items)
  /// 2. Open Food Facts (food, fallback)
  static Future<ScannedProduct?> lookupBarcode(String barcode) async {
    // Try Open Products Facts first (household products)
    final opfResult = await _lookup(
      '$_opfBaseUrl/$barcode.json',
      source: 'Open Products Facts',
    );
    if (opfResult != null) return opfResult;

    // Fallback to Open Food Facts
    final offResult = await _lookup(
      '$_offBaseUrl/$barcode.json',
      source: 'Open Food Facts',
    );
    return offResult;
  }

  static Future<ScannedProduct?> _lookup(String url, {required String source}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'HomeInventoryApp - Flutter',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Both APIs return { product: { ... } }
      if (data['product'] == null) return null;

      final product = data['product'] as Map<String, dynamic>;

      final rawName = product['product_name'] as String?;
      final rawBrands = product['brands'] as String?;
      final rawQuantity = product['quantity'] as String?;

      // Clean up brands: take only the first one
      final brand = _extractFirstBrand(rawBrands);

      // Parse quantity: extract number from "400 g" or "750 ml"
      final parsedQuantity = _parseQuantity(rawQuantity);

      return ScannedProduct(
        name: rawName,
        brand: brand,
        quantity: parsedQuantity,
        rawQuantity: rawQuantity,
      );
    } catch (e) {
      return null;
    }
  }

  static String? _extractFirstBrand(String? brands) {
    if (brands == null || brands.isEmpty) return null;
    // APIs return comma-separated brands: "Nutella,Ferrero"
    return brands.split(',').first.trim();
  }

  static int? _parseQuantity(String? quantityStr) {
    if (quantityStr == null || quantityStr.isEmpty) return null;
    // Try to extract the first number from strings like "400 g", "750 ml", "1.5 L"
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(quantityStr);
    if (match == null) return null;
    final numberStr = match.group(1)!.replaceAll(',', '.');
    final value = double.tryParse(numberStr);
    if (value == null) return null;
    return value.round();
  }
}
