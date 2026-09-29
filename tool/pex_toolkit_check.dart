// ignore_for_file: avoid_print
import 'package:pex_user_flutter/core/util/pex_toolkit.dart';
void main() {
  print('73级 hash: ${hashStable('abc+123')}');
  print('email ok: ${validateEmail('a@b.com')} / bad: ${validateEmail('a@b')}');
  print('phone CN ok: ${validatePhone('+86-13800138000')} / bad: ${validatePhone('+86-123')}');
  print('phone US ok: ${validatePhone('+1-2025550123')} / bad: ${validatePhone('+1-123')}');
  print('phone unknown itc: ${validatePhone('+999-1234567890')}');
  print('numberPrecision: ${numberPrecision(3.14159, 2)} / ${numberPrecision(null)}');
}
