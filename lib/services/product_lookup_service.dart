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
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  static Future<ScannedProduct?> lookupBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$barcode.json'),
        headers: {
          'User-Agent': 'HomeInventoryApp - Flutter',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Open Food Facts returns { product: { ... } }
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
    // Open Food Facts returns comma-separated brands: "Nutella,Ferrero"
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
