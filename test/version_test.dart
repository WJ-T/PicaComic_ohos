import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/utils/version.dart';

void main() {
  test('needUpdate handles GitHub release tag prefixes', () {
    expect(needUpdate('4.8.3', 'v4.8.1'), isFalse);
    expect(needUpdate('4.8.1', 'v4.8.3'), isTrue);
    expect(needUpdate('4.8.3+46315', 'v4.8.3'), isFalse);
  });
}
