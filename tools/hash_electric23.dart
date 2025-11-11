import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  var password = 'Electric:23';
  var bytes = utf8.encode(password);
  var hash = sha256.convert(bytes);
  print(hash.toString());
}
