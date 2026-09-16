class Formatters {
  /// Format currency with Indian Rupee symbol or custom symbol
  static String currency(double amount, {String symbol = '₹'}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Format Indian numbering system: last 3 digits, then groups of 2
    String formattedInteger;
    if (integerPart.length <= 3) {
      formattedInteger = integerPart;
    } else {
      final lastThree = integerPart.substring(integerPart.length - 3);
      final remaining = integerPart.substring(0, integerPart.length - 3);
      final buffer = StringBuffer();
      for (int i = 0; i < remaining.length; i++) {
        if (i > 0 && (remaining.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(remaining[i]);
      }
      buffer.write(',');
      buffer.write(lastThree);
      formattedInteger = buffer.toString();
    }

    final formatted = '$symbol$formattedInteger${decimalPart == '00' ? '' : '.$decimalPart'}';
    return isNegative ? '-$formatted' : formatted;
  }

  /// Compact currency format (e.g. ₹1.2k, ₹1.5L)
  static String compactCurrency(double amount, {String symbol = '₹'}) {
    if (amount.abs() >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount.abs() >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return currency(amount, symbol: symbol);
  }

  /// Format date: e.g. "Today, 4:30 PM", "Yesterday", "11 Sep 2026"
  static String date(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (isToday) {
      return 'Today, $timeStr';
    } else if (isYesterday) {
      return 'Yesterday, $timeStr';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $timeStr';
    }
  }

  /// Format short date: e.g. "11 Sep 2026"
  static String shortDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  /// Generate short human-readable ID / invoice code
  static String generateInvoiceCode(String prefix, int counter) {
    return '$prefix-${counter.toString().padLeft(4, '0')}';
  }
}
