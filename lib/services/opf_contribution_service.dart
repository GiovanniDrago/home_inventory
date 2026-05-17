import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/opf_credentials.dart';

class OpfContributionService {
  static const String _submitUrl = 'https://world.openproductsfacts.org/cgi/product_jqm2.pl';

  static Future<bool> submitProduct({
    required OpfCredentials credentials,
    required String barcode,
    required String productName,
    required String brand,
    String? quantity,
    String? category,
    Uint8List? photoBytes,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_submitUrl));

      // Authentication
      request.fields['user_id'] = credentials.username;
      request.fields['password'] = credentials.password;

      // Required fields
      request.fields['code'] = barcode;
      request.fields['product_name'] = productName;
      request.fields['brands'] = brand;

      // Optional fields
      if (quantity != null && quantity.isNotEmpty) {
        request.fields['quantity'] = quantity;
      }
      if (category != null && category.isNotEmpty) {
        request.fields['categories'] = category;
      }

      // Photo upload
      if (photoBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'imgupload_front',
            photoBytes,
            filename: 'front.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['status'] == 1 || data['status_verbose']?.toString().toLowerCase().contains('saved') == true;
    } catch (e) {
      return false;
    }
  }
}
