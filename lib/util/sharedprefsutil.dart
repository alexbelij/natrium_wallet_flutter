import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalium_wallet_flutter/util/encrypt.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';

/**
 * Singleton wrapper for shared preferences
 */
class SharedPrefsUtil {
  SharedPrefsUtil._internal();
  static final SharedPrefsUtil _singleton = new SharedPrefsUtil._internal();
  static SharedPrefsUtil get inst => _singleton;

  // Keys
  static const String seed_backed_up_key = 'fkalium_seed_backup';
  static const String app_uuid_key = 'fkalium_app_uuid';

  // For plain-text data
  Future<void> set(String key, value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (value is bool) {
      sharedPreferences.setBool(key, value);
    } else if (value is String) {
      sharedPreferences.setString(key, value);
    } else if (value is double) {
      sharedPreferences.setDouble(key, value);
    } else if (value is int) {
      sharedPreferences.setInt(key, value);
    }
  }

  Future<dynamic> get(String key, {dynamic defaultValue}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.get(key) ?? defaultValue;
  }

  // For encrypted data
  Future<void> setEncrypted(String key, String value) async {
    // Retrieve/Generate encryption password
    String secret = await Vault.inst.getEncryptionPhrase();
    if (secret == null) {
      secret = AESEncrypter.generateEncryptionSecret();
      await Vault.inst.writeEncryptionPhrase(secret);
    }
    // Encrypt and save
    AESEncrypter encrypter = new AESEncrypter(secret);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, encrypter.encrypt(value));
  }

  Future<String> getEncrypted(String key) async {
    String secret = await Vault.inst.getEncryptionPhrase();
    if (secret == null) return null;
    // Decrypt and return
    AESEncrypter encrypter = new AESEncrypter(secret);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encrypted = prefs.get(key);
    if (encrypted == null) return null;
    return encrypter.decrypt(encrypted);
  }

  // Key-specific helpers
  Future<void> setSeedBackedUp(bool value) async {
    return await set(seed_backed_up_key, value);
  }

  Future<bool> getSeedBackedUp() async {
    return await get(seed_backed_up_key, defaultValue: false);
  }

  Future<void> setUuid(String uuid) async {
    return await setEncrypted(app_uuid_key, uuid);
  }

  Future<String> getUuid() async {
    return await getEncrypted(app_uuid_key);
  }

  // For logging out
  Future<void> deleteAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(seed_backed_up_key);
    prefs.remove(app_uuid_key);
  }
}