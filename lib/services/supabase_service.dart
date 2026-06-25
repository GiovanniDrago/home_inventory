import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../models/house.dart';
import '../models/profile.dart';
import '../models/room.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_history.dart';
import '../models/invitation.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // Auth
  static User? get currentUser => _client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Profile
  static Future<Profile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return Profile.fromMap(response);
  }

  static Future<Profile> createProfile({
    required String userId,
    required String nickname,
    required String email,
  }) async {
    final data = {
      'id': userId,
      'nickname': nickname,
      'email': email,
    };
    final response = await _client.from('profiles').upsert(data).select().single();
    return Profile.fromMap(response);
  }

  static Future<void> updateProfileHouse(String userId, String? houseId) async {
    final user = _client.auth.currentUser;
    final email = user?.email ?? '';
    final nickname = email.isNotEmpty ? email.split('@').first : userId.substring(0, 8);
    await _client.from('profiles').upsert({
      'id': userId,
      'nickname': nickname,
      'email': email,
      'house_id': houseId,
    });
  }

  static Future<bool> isNicknameTaken(String nickname) async {
    final response = await _client
        .from('profiles')
        .select('id')
        .ilike('nickname', nickname)
        .maybeSingle();
    return response != null;
  }

  static Future<bool> isEmailTaken(String email) async {
    final response = await _client
        .from('profiles')
        .select('id')
        .ilike('email', email)
        .maybeSingle();
    return response != null;
  }

  // House
  static Future<House> createHouse({
    required String name,
    required String createdBy,
  }) async {
    final data = {
      'name': name,
      'created_by': createdBy,
    };
    final response = await _client.from('houses').insert(data).select().single();
    return House.fromMap(response);
  }

  static Future<House?> getHouse(String houseId) async {
    final response = await _client
        .from('houses')
        .select()
        .eq('id', houseId)
        .maybeSingle();
    if (response == null) return null;
    return House.fromMap(response);
  }

  static Future<List<Map<String, dynamic>>> searchHouses(String query) async {
    final response = await _client
        .from('houses')
        .select('*, creator:profiles!houses_created_by_fkey(nickname, email)')
        .ilike('name', '%$query%');
    return (response as List<dynamic>).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final creator = map['creator'] as Map?;
      return {
        'house': House.fromMap(map),
        'creator_nickname': creator?['nickname'] as String? ?? 'Unknown',
        'creator_email': creator?['email'] as String? ?? '',
      };
    }).toList();
  }

  // Rooms
  static Future<List<Room>> getRooms(String houseId) async {
    final response = await _client
        .from('rooms')
        .select()
        .eq('house_id', houseId)
        .order('created_at');
    return (response as List<dynamic>).map((e) => Room.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<Room> createRoom({
    required String name,
    required String houseId,
  }) async {
    final data = {
      'name': name,
      'house_id': houseId,
    };
    final response = await _client.from('rooms').insert(data).select().single();
    return Room.fromMap(response);
  }

  static Future<void> updateRoom(String roomId, String name) async {
    await _client.from('rooms').update({'name': name}).eq('id', roomId);
  }

  static Future<void> deleteRoom(String roomId) async {
    await _client.from('rooms').delete().eq('id', roomId);
  }

  // Categories
  static Future<List<Category>> getCategories(String houseId) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('house_id', houseId)
        .order('name');
    return (response as List<dynamic>).map((e) => Category.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<Category> createCategory({
    required String name,
    required String houseId,
    String? description,
  }) async {
    final data = {
      'name': name,
      'house_id': houseId,
      'description': description,
    };
    final response = await _client.from('categories').insert(data).select().single();
    return Category.fromMap(response);
  }

  static Future<void> updateCategory(String categoryId, {String? name, String? description}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (data.isNotEmpty) {
      await _client.from('categories').update(data).eq('id', categoryId);
    }
  }

  static Future<void> deleteCategory(String categoryId) async {
    // Reassign products to "Altro" category or set null
    await _client.from('products').update({'category_id': null}).eq('category_id', categoryId);
    await _client.from('categories').delete().eq('id', categoryId);
  }

  static Future<void> seedDefaultCategories(String houseId) async {
    final defaults = [
      {'name': 'Prodotti per il bagno', 'description': 'Prodotti per la pulizia del bagno'},
      {'name': 'Prodotti per il corpo', 'description': 'Prodotti per la cura del corpo'},
      {'name': 'Prodotti per il pavimento', 'description': 'Prodotti per la pulizia dei pavimenti'},
      {'name': 'Prodotti per la cucina', 'description': 'Prodotti per la pulizia della cucina'},
      {'name': 'Prodotti per il bucato', 'description': 'Detersivi e ammorbidenti'},
      {'name': 'Prodotti per i vetri', 'description': 'Prodotti per la pulizia dei vetri'},
      {'name': 'Prodotti per la cura dei tessuti', 'description': 'Prodotti per tessuti e stoffe'},
      {'name': 'Prodotti per l\'igiene personale', 'description': 'Prodotti per l\'igiene quotidiana'},
      {'name': 'Prodotti per il giardino', 'description': 'Prodotti per la cura del giardino'},
      {'name': 'Altro', 'description': 'Altre categorie'},
    ];
    for (final cat in defaults) {
      await _client.from('categories').insert({
        ...cat,
        'house_id': houseId,
      });
    }
  }

  // Products
  static Future<List<Product>> getProducts(String houseId, {String? roomId}) async {
    var query = _client.from('products').select().eq('house_id', houseId);
    if (roomId != null) {
      query = query.eq('room_id', roomId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List<dynamic>).map((e) => Product.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<Product> createProduct({
    required String name,
    String? brand,
    String? note,
    required int quantity,
    double? price,
    required String roomId,
    String? categoryId,
    required String houseId,
  }) async {
    final data = {
      'name': name,
      'brand': brand,
      'note': note,
      'quantity': quantity,
      'price': price,
      'room_id': roomId,
      'category_id': categoryId,
      'house_id': houseId,
      'status': 'active',
    };
    final response = await _client.from('products').insert(data).select().single();
    final product = Product.fromMap(response);
    await _logHistory(product.id, 'created', {'product': product.toMap()});
    return product;
  }

  static Future<void> updateProduct(String productId, {
    String? name,
    String? brand,
    String? note,
    int? quantity,
    double? price,
    String? roomId,
    String? categoryId,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (brand != null) data['brand'] = brand;
    if (note != null) data['note'] = note;
    if (quantity != null) data['quantity'] = quantity;
    if (price != null) data['price'] = price;
    if (roomId != null) data['room_id'] = roomId;
    if (categoryId != null) data['category_id'] = categoryId;
    data['updated_at'] = DateTime.now().toIso8601String();

    if (data.isNotEmpty) {
      await _client.from('products').update(data).eq('id', productId);
      await _logHistory(productId, 'updated', data);
    }
  }

  static Future<void> moveProduct(String productId, String newRoomId) async {
    await _client.from('products').update({
      'room_id': newRoomId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
    await _logHistory(productId, 'moved', {'new_room_id': newRoomId});
  }

  static Future<void> terminateProduct(String productId) async {
    await _client.from('products').update({
      'status': 'terminated',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', productId);
    await _logHistory(productId, 'terminated', {});
  }

  static Future<void> _logHistory(String productId, String action, Map<String, dynamic> details) async {
    await _client.from('product_history').insert({
      'product_id': productId,
      'action': action,
      'details': details,
    });
  }

  static Future<List<ProductHistory>> getProductHistory(String productId) async {
    final response = await _client
        .from('product_history')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>).map((e) => ProductHistory.fromMap(e as Map<String, dynamic>)).toList();
  }

  // Invitations
  static Future<Invitation> createInvitation({
    required String fromUserId,
    required String toEmail,
    required String houseId,
  }) async {
    final data = {
      'from_user_id': fromUserId,
      'to_email': toEmail,
      'house_id': houseId,
      'status': 'pending',
    };
    final response = await _client.from('invitations').insert(data).select().single();
    return Invitation.fromMap(response);
  }

  static Future<List<Invitation>> getIncomingInvitations(String userId) async {
    // Get houses created by this user, then invitations to those houses
    final housesResponse = await _client.from('houses').select('id').eq('created_by', userId);
    final houseIds = (housesResponse as List<dynamic>).map((e) => e['id'] as String).toList();
    if (houseIds.isEmpty) return [];

    final response = await _client
        .from('invitations')
        .select('*, profiles!invitations_from_user_id_fkey(nickname), houses(name)')
        .inFilter('house_id', houseIds)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['from_user_nickname'] = (map['profiles'] as Map?)?['nickname'];
      map['house_name'] = (map['houses'] as Map?)?['name'];
      return Invitation.fromMap(map);
    }).toList();
  }

  static Future<List<Invitation>> getSentInvitations(String userId) async {
    final response = await _client
        .from('invitations')
        .select('*, houses(name)')
        .eq('from_user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      map['house_name'] = (map['houses'] as Map?)?['name'];
      return Invitation.fromMap(map);
    }).toList();
  }

  static Future<void> respondToInvitation(String invitationId, String status) async {
    await _client.from('invitations').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', invitationId);

    if (status == 'accepted') {
      final inv = await _client.from('invitations').select().eq('id', invitationId).single();
      final invitation = Invitation.fromMap(inv);
      // Find the profile by email and update house_id
      final profiles = await _client.from('profiles').select().eq('email', invitation.toEmail);
      if ((profiles as List).isNotEmpty) {
        final profileId = profiles.first['id'] as String;
        await _client.from('profiles').update({'house_id': invitation.houseId}).eq('id', profileId);
      }
    }
  }

  // Realtime subscriptions
  static RealtimeChannel subscribeToProducts(String houseId, Function(dynamic) callback) {
    return _client
        .channel('products:$houseId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: callback,
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToRooms(String houseId, Function(dynamic) callback) {
    return _client
        .channel('rooms:$houseId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          callback: callback,
        )
        .subscribe();
  }

  static void unsubscribeChannel(String channelName) {
    _client.channel(channelName).unsubscribe();
  }
}
