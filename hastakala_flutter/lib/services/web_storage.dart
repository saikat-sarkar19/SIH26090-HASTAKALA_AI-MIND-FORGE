import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart';

class WebStorage {
  static void setItem(String key, String value) => implSetItem(key, value);
  static String? getItem(String key) => implGetItem(key);
  static void removeItem(String key) => implRemoveItem(key);
}
