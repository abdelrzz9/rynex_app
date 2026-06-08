/// Local account-level summary for persisted drawing elements.
///
/// [colorCounts] stores ARGB32 color values as keys and the number of elements
/// using each color as values.
class DrawingAccountSummary {
  const DrawingAccountSummary({
    required this.accountNumber,
    this.colorCounts = const {},
  });

  final int accountNumber;
  final Map<int, int> colorCounts;

  int get elementCount =>
      colorCounts.values.fold(0, (sum, count) => sum + count);

  Set<int> get colors => colorCounts.keys.toSet();

  DrawingAccountSummary addColorCount(int color, int count) {
    return DrawingAccountSummary(
      accountNumber: accountNumber,
      colorCounts: {
        ...colorCounts,
        color: (colorCounts[color] ?? 0) + count,
      },
    );
  }
}
