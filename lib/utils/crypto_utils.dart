import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  static String md5Encrypt(String input) {
    final bytes = utf8.encode(input); // 将输入字符串转换为字节
    final digest = md5.convert(bytes); // 使用 MD5 算法计算哈希值
    return digest.toString(); // 将哈希值转换为十六进制字符串
  }

  static String sha1Encrypt(String input) {
    final bytes = utf8.encode(input); // 将输入字符串转换为字节
    final digest = sha1.convert(bytes); // 使用 SHA1 算法计算哈希值
    return digest.toString(); // 将哈希值转换为十六进制字符串
  }
}
