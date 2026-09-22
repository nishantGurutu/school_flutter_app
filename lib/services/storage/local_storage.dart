import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/models/user_model.dart';

class StorageHelper {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> initialize() async {
    // No initialization needed for Secure Storage, kept for compatibility
  }

  static Future<void> clear() async {
    await _secureStorage.deleteAll();
  }

  // Storage Keys matching login API response payload
  static const String _keyAccessToken = "accessToken";
  static const String _keyRefreshToken = "refreshToken";
  static const String _keyExpiresAt = "expiresAt";
  static const String _keyTokenType = "tokenType";
  static const String _keyUserId = "userId";
  static const String _keyEmail = "email";
  static const String _keyName = "name";
  static const String _keyRole = "role";
  static const String _keyClassName = "className";
  static const String _keyDetails = "details";
  static const String _keyAvatarUrl = "avatarUrl";
  static const String _keyEntityId = "entityId";
  static const String _keyPhone = "phone";
  static const String _keyDepartment = "department";

  // Backward compatibility keys
  static const String _keyJwtToken = _keyAccessToken;

  /// Save full login response map into secure storage
  static Future<void> saveLoginResponse(Map<String, dynamic> json) async {
    if (json.containsKey('accessToken') && json['accessToken'] != null) {
      await setAccessToken(json['accessToken'].toString());
    }
    if (json.containsKey('refreshToken') && json['refreshToken'] != null) {
      await setRefreshToken(json['refreshToken'].toString());
    }
    if (json.containsKey('expiresAt') && json['expiresAt'] != null) {
      await setExpiresAt(json['expiresAt'] is int
          ? json['expiresAt']
          : int.tryParse(json['expiresAt'].toString()) ?? 0);
    }
    if (json.containsKey('tokenType') && json['tokenType'] != null) {
      await setTokenType(json['tokenType'].toString());
    }
    if (json.containsKey('userId') && json['userId'] != null) {
      await setUserId(json['userId'].toString());
    }
    if (json.containsKey('email') && json['email'] != null) {
      await setEmail(json['email'].toString());
    }
    if (json.containsKey('name') && json['name'] != null) {
      await setName(json['name'].toString());
    }
    if (json.containsKey('role') && json['role'] != null) {
      await setRole(json['role'].toString());
    }
    if (json.containsKey('className') && json['className'] != null) {
      await setClassName(json['className'].toString());
    }
    if (json.containsKey('details') && json['details'] != null) {
      await setDetails(json['details'].toString());
    }
    if (json.containsKey('avatarUrl') && json['avatarUrl'] != null) {
      await setAvatarUrl(json['avatarUrl'].toString());
    }
    if (json.containsKey('entityId') && json['entityId'] != null) {
      await setEntityId(json['entityId'].toString());
    }
    if (json.containsKey('phone') && json['phone'] != null) {
      await setPhone(json['phone'].toString());
    }
    if (json.containsKey('department') && json['department'] != null) {
      await setDepartment(json['department'].toString());
    }
  }

  // Setters
  static Future<void> setAccessToken(String token) async =>
      await _secureStorage.write(key: _keyAccessToken, value: token);

  static Future<void> saveJwtToken(String token) async =>
      await setAccessToken(token);

  static Future<void> setRefreshToken(String refreshToken) async =>
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);

  static Future<void> setExpiresAt(int expiresAt) async =>
      await _secureStorage.write(key: _keyExpiresAt, value: expiresAt.toString());

  static Future<void> setTokenType(String tokenType) async =>
      await _secureStorage.write(key: _keyTokenType, value: tokenType);

  static Future<void> setUserId(String userId) async =>
      await _secureStorage.write(key: _keyUserId, value: userId);

  static Future<void> setEmail(String email) async =>
      await _secureStorage.write(key: _keyEmail, value: email);

  static Future<void> setName(String name) async =>
      await _secureStorage.write(key: _keyName, value: name);

  static Future<void> setRole(String role) async =>
      await _secureStorage.write(key: _keyRole, value: role);

  static Future<void> setClassName(String? className) async {
    if (className != null) {
      await _secureStorage.write(key: _keyClassName, value: className);
    } else {
      await _secureStorage.delete(key: _keyClassName);
    }
  }

  static Future<void> setDetails(String? details) async {
    if (details != null) {
      await _secureStorage.write(key: _keyDetails, value: details);
    } else {
      await _secureStorage.delete(key: _keyDetails);
    }
  }

  static Future<void> setAvatarUrl(String? avatarUrl) async {
    if (avatarUrl != null) {
      await _secureStorage.write(key: _keyAvatarUrl, value: avatarUrl);
    } else {
      await _secureStorage.delete(key: _keyAvatarUrl);
    }
  }

  static Future<void> setEntityId(String? entityId) async {
    if (entityId != null) {
      await _secureStorage.write(key: _keyEntityId, value: entityId);
    } else {
      await _secureStorage.delete(key: _keyEntityId);
    }
  }

  static Future<void> setPhone(String? phone) async {
    if (phone != null) {
      await _secureStorage.write(key: _keyPhone, value: phone);
    } else {
      await _secureStorage.delete(key: _keyPhone);
    }
  }

  static Future<void> setDepartment(String? department) async {
    if (department != null) {
      await _secureStorage.write(key: _keyDepartment, value: department);
    } else {
      await _secureStorage.delete(key: _keyDepartment);
    }
  }

  // Getters
  static Future<String?> getAccessToken() async =>
      await _secureStorage.read(key: _keyAccessToken);

  static Future<String?> getJwtToken() async =>
      await getAccessToken();

  static Future<String?> getRefreshToken() async =>
      await _secureStorage.read(key: _keyRefreshToken);

  static Future<int?> getExpiresAt() async {
    final value = await _secureStorage.read(key: _keyExpiresAt);
    return value != null ? int.tryParse(value) : null;
  }

  static Future<String?> getTokenType() async =>
      await _secureStorage.read(key: _keyTokenType);

  static Future<String?> getUserId() async =>
      await _secureStorage.read(key: _keyUserId);

  static Future<String?> getEmail() async =>
      await _secureStorage.read(key: _keyEmail);

  static Future<String?> getName() async =>
      await _secureStorage.read(key: _keyName);

  static Future<String?> getRole() async =>
      await _secureStorage.read(key: _keyRole);

  static Future<String?> getClassName() async =>
      await _secureStorage.read(key: _keyClassName);

  static Future<String?> getDetails() async =>
      await _secureStorage.read(key: _keyDetails);

  static Future<String?> getAvatarUrl() async =>
      await _secureStorage.read(key: _keyAvatarUrl);

  static Future<String?> getEntityId() async =>
      await _secureStorage.read(key: _keyEntityId);

  static Future<String?> getPhone() async =>
      await _secureStorage.read(key: _keyPhone);

  static Future<String?> getDepartment() async =>
      await _secureStorage.read(key: _keyDepartment);

  /// Check if user has an active session token stored
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Retrieve stored user session as a UserModel object
  static Future<UserModel?> getUserSession() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return null;

    final userId = await getUserId() ?? '1';
    final name = await getName() ?? 'User';
    final email = await getEmail() ?? '';
    final roleStr = await getRole() ?? 'STUDENT';
    final avatarUrl = await getAvatarUrl();
    final className = await getClassName();
    final details = await getDetails();
    final refreshToken = await getRefreshToken();
    final expiresAt = await getExpiresAt();
    final tokenType = await getTokenType();
    final entityId = await getEntityId();
    final phone = await getPhone();
    final department = await getDepartment();

    final json = {
      'userId': userId,
      'name': name,
      'email': email,
      'role': roleStr,
      'avatarUrl': avatarUrl,
      'className': className,
      'details': details,
      'accessToken': token,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
      'tokenType': tokenType,
      'entityId': entityId,
      'phone': phone,
      'department': department,
    };

    return UserModel.fromJson(json, token: token, refreshToken: refreshToken);
  }
}

