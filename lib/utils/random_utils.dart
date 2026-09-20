import 'dart:math';

class RandomUtils {
  static Random _random = Random();

  static void seed(int? seedValue) {
    _random = seedValue != null ? Random(seedValue) : Random();
  }

  static double nextDouble() => _random.nextDouble();
  static int nextInt(int max) => _random.nextInt(max);
  static bool nextBool() => _random.nextBool();
}
