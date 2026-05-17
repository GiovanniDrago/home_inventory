import 'dart:convert';
import 'package:http/http.dart' as http;

class ScannedProduct {
  final String? name;
  final String? brand;
  final String? quantity;

  ScannedProduct({this.name, this.brand, this.quantity});
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
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Open Food Facts returns { product: { ... } }
      if (data['product'] == null) return null;

      final product = data['product'] as Map<String, dynamic>;

      return ScannedProduct(
        name: product['product_name'] as String?,
        brand: product['brands'] as String?,
        quantity: product['quantity'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}
