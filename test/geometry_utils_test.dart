import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rynex_app/core/utils/geometry_utils.dart';

void main() {
  group('perpendicularDistance', () {
    test('returns 0 for point on line', () {
      expect(perpendicularDistance(const Offset(5, 5), const Offset(0, 0), const Offset(10, 10)), closeTo(0, 1e-10));
    });

    test('returns correct distance for point off line', () {
      expect(perpendicularDistance(const Offset(5, 0), const Offset(0, 0), const Offset(10, 0)), closeTo(0, 1e-10));
    });

    test('handles vertical line', () {
      expect(perpendicularDistance(const Offset(0, 5), const Offset(0, 0), const Offset(0, 10)), closeTo(0, 1e-10));
    });

    test('handles degenerate line (same points)', () {
      final p = const Offset(5, 5);
      expect(perpendicularDistance(p, p, p), closeTo(0, 1e-10));
    });
  });

  group('simplifyPoints', () {
    test('returns same for 2 points', () {
      final pts = [const Offset(0, 0), const Offset(10, 10)];
      expect(simplifyPoints(pts, 2), pts);
    });

    test('removes collinear middle points', () {
      final pts = [const Offset(0, 0), const Offset(5, 5), const Offset(10, 10)];
      expect(simplifyPoints(pts, 2), [const Offset(0, 0), const Offset(10, 10)]);
    });
  });

}

