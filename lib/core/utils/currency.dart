import 'package:intl/intl.dart';

class Currency {
  Currency._();

  static final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num value) => _fmt.format(value);
}
