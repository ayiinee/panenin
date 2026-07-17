import 'package:flutter_test/flutter_test.dart';
import 'package:panenin/core/validation/input_validators.dart';

void main() {
  group('InputValidators', () {
    test('memvalidasi teks wajib dan batas panjang', () {
      expect(
        InputValidators.requiredText('', label: 'Nama produk', minLength: 2),
        'Nama produk wajib diisi.',
      );
      expect(
        InputValidators.requiredText('A', label: 'Nama produk', minLength: 2),
        'Nama produk minimal 2 karakter.',
      );
      expect(
        InputValidators.requiredText(
          'Cabai Merah',
          label: 'Nama produk',
          minLength: 2,
        ),
        isNull,
      );
    });

    test('menolak email dan angka transaksi yang tidak valid', () {
      expect(InputValidators.email('petani@'), isNotNull);
      expect(InputValidators.email('petani@panenin.id'), isNull);
      expect(
        InputValidators.positiveInteger('0', label: 'Harga jual'),
        'Harga jual harus lebih dari 0.',
      );
      expect(
        InputValidators.positiveInteger('12000', label: 'Harga jual'),
        isNull,
      );
    });

    test('memvalidasi pencarian dan pesan chat', () {
      expect(InputValidators.search(' '), isNotNull);
      expect(InputValidators.search('Tomat'), isNull);
      expect(InputValidators.chatMessage('\n'), isNotNull);
      expect(InputValidators.chatMessage('Bisa kirim pagi?'), isNull);
    });
  });
}
