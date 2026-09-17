// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void implSetItem(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

String? implGetItem(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void implRemoveItem(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}
