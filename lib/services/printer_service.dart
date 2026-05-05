import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../models/order_model.dart';
import '../utils/currency_formatter.dart';

class PrinterService extends ChangeNotifier {
  static const _prefKey = 'saved_printer_address';
  static const _prefNameKey = 'saved_printer_name';

  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _isReconnecting = false;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;

  PrinterService() {
    _autoConnect();
  }

  // ── Auto-connect on startup ──

  Future<void> _autoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString(_prefKey);
    if (savedAddress == null) return;

    final granted = await requestPermissions();
    if (!granted) return;

    _isReconnecting = true;
    notifyListeners();

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final device = devices.cast<BluetoothDevice?>().firstWhere(
        (d) => d?.address == savedAddress,
        orElse: () => null,
      );

      if (device != null) {
        await _connectInternal(device);
      }
    } catch (e) {
      debugPrint('Auto-connect error: $e');
    }

    _isReconnecting = false;
    notifyListeners();
  }

  // ── Permissions ──

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every(
      (s) => s.isGranted || s.isLimited,
    );
  }

  // ── Bluetooth ──

  Future<List<BluetoothDevice>> getPairedDevices() async {
    final granted = await requestPermissions();
    if (!granted) return [];

    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      debugPrint('BT getPairedDevices error: $e');
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    final success = await _connectInternal(device);
    if (success) {
      // Save MAC address for auto-reconnect
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, device.address);
      if (device.name != null) {
        await prefs.setString(_prefNameKey, device.name!);
      }
    }
    return success;
  }

  Future<bool> _connectInternal(BluetoothDevice device) async {
    try {
      disconnect(clearSaved: false);
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      _connection!.input?.listen((_) {}).onDone(() {
        _isConnected = false;
        _connection = null;
        notifyListeners();
        // Try to reconnect after disconnect
        _scheduleReconnect();
      });

      return true;
    } catch (e) {
      debugPrint('BT connect error: $e');
      _isConnected = false;
      _connection = null;
      _connectedDevice = null;
      notifyListeners();
      return false;
    }
  }

  void _scheduleReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString(_prefKey);
    if (savedAddress == null) return;

    // Wait a bit before retrying
    await Future.delayed(const Duration(seconds: 5));

    if (_isConnected) return; // Already reconnected

    _isReconnecting = true;
    notifyListeners();

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final device = devices.cast<BluetoothDevice?>().firstWhere(
        (d) => d?.address == savedAddress,
        orElse: () => null,
      );

      if (device != null && !_isConnected) {
        await _connectInternal(device);
      }
    } catch (e) {
      debugPrint('Reconnect error: $e');
    }

    _isReconnecting = false;
    notifyListeners();
  }

  void disconnect({bool clearSaved = true}) {
    try {
      _connection?.dispose();
    } catch (_) {}
    _connection = null;
    _connectedDevice = null;
    _isConnected = false;

    if (clearSaved) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove(_prefKey);
        prefs.remove(_prefNameKey);
      });
    }

    notifyListeners();
  }

  // ── ESC/POS Commands ──

  static const _esc = 0x1B;
  static const _gs = 0x1D;

  Uint8List _cmd(List<int> bytes) => Uint8List.fromList(bytes);

  Uint8List get _reset => _cmd([_esc, 0x40]);
  Uint8List get _boldOn => _cmd([_esc, 0x45, 0x01]);
  Uint8List get _boldOff => _cmd([_esc, 0x45, 0x00]);
  Uint8List get _alignCenter => _cmd([_esc, 0x61, 0x01]);
  Uint8List get _alignLeft => _cmd([_esc, 0x61, 0x00]);
  Uint8List get _doubleSizeOn => _cmd([_gs, 0x21, 0x11]);
  Uint8List get _doubleSizeOff => _cmd([_gs, 0x21, 0x00]);
  Uint8List get _cut => _cmd([_gs, 0x56, 0x00]);
  Uint8List get _feedLines => _cmd([_esc, 0x64, 0x04]);

  Uint8List _text(String text) {
    return Uint8List.fromList(latin1.encode(text));
  }

  Uint8List _line(String text) {
    final bytes = <int>[];
    bytes.addAll(_text(text));
    bytes.add(0x0A);
    return Uint8List.fromList(bytes);
  }

  String _padLine(String left, String right, {int width = 32}) {
    final spaces = width - left.length - right.length;
    if (spaces <= 0) return '$left $right';
    return '$left${' ' * spaces}$right';
  }

  String _separator({int width = 32}) => '-' * width;
  String _doubleSeparator({int width = 32}) => '=' * width;

  // ── Receipt Generation ──

  Future<void> printReceipt({
    required Payment payment,
    required Order order,
    required int tableNumber,
  }) async {
    if (!_isConnected || _connection == null) return;

    try {
      final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
      final bytes = <int>[];

      bytes.addAll(_reset);

      // Header
      bytes.addAll(_alignCenter);
      bytes.addAll(_line(_doubleSeparator()));
      bytes.addAll(_boldOn);
      bytes.addAll(_doubleSizeOn);
      bytes.addAll(_line('ZEN POS'));
      bytes.addAll(_doubleSizeOff);
      bytes.addAll(_boldOff);
      bytes.addAll(_line(_doubleSeparator()));

      // Table + date
      bytes.addAll(_alignLeft);
      bytes.addAll(_line(_padLine(
        'Stul: $tableNumber',
        dateFormat.format(payment.timestamp),
      )));
      bytes.addAll(_line(_separator()));

      // Items
      for (final item in order.items) {
        final qty = '${item.quantity}x';
        final name = item.product.name;
        final price = CurrencyFormatter.format(item.product.price * item.quantity);
        bytes.addAll(_line(_padLine('$qty $name', price)));
      }

      bytes.addAll(_line(_separator()));

      // Subtotal
      bytes.addAll(_line(_padLine(
        'Mezisoucet:',
        CurrencyFormatter.format(order.subtotal),
      )));

      // VAT
      bytes.addAll(_line(_padLine(
        'DPH 21%:',
        CurrencyFormatter.format(order.vat),
      )));

      // Total
      bytes.addAll(_boldOn);
      bytes.addAll(_line(_padLine(
        'CELKEM:',
        CurrencyFormatter.format(order.total),
      )));
      bytes.addAll(_boldOff);

      // Tip
      if (payment.tip > 0) {
        bytes.addAll(_line(_padLine(
          'Spropitne:',
          CurrencyFormatter.format(payment.tip),
        )));
        bytes.addAll(_boldOn);
        bytes.addAll(_line(_padLine(
          'CELKEM S PROPITNYM:',
          CurrencyFormatter.format(payment.totalWithTip),
        )));
        bytes.addAll(_boldOff);
      }

      bytes.addAll(_line(_separator()));

      // Payment method
      bytes.addAll(_line(_padLine(
        'Platba:',
        payment.method.title,
      )));

      // Footer
      bytes.addAll(_line(_doubleSeparator()));
      bytes.addAll(_alignCenter);
      bytes.addAll(_line('Dekujeme za navstevu!'));
      bytes.addAll(_line(_doubleSeparator()));

      // Feed + Cut
      bytes.addAll(_feedLines);
      bytes.addAll(_cut);

      _connection!.output.add(Uint8List.fromList(bytes));
      await _connection!.output.allSent;
    } catch (e) {
      debugPrint('Print error: $e');
    }
  }

  Future<void> printTestReceipt() async {
    if (!_isConnected || _connection == null) return;

    try {
      final bytes = <int>[];
      bytes.addAll(_reset);
      bytes.addAll(_alignCenter);
      bytes.addAll(_line(_doubleSeparator()));
      bytes.addAll(_boldOn);
      bytes.addAll(_doubleSizeOn);
      bytes.addAll(_line('ZEN POS'));
      bytes.addAll(_doubleSizeOff);
      bytes.addAll(_boldOff);
      bytes.addAll(_line(_doubleSeparator()));
      bytes.addAll(_line(''));
      bytes.addAll(_line('Testovaci tisk'));
      bytes.addAll(_line('Tiskarna funguje spravne!'));
      bytes.addAll(_line(''));
      bytes.addAll(_line(DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())));
      bytes.addAll(_line(''));
      bytes.addAll(_line(_doubleSeparator()));
      bytes.addAll(_feedLines);
      bytes.addAll(_cut);

      _connection!.output.add(Uint8List.fromList(bytes));
      await _connection!.output.allSent;
    } catch (e) {
      debugPrint('Test print error: $e');
    }
  }

  @override
  void dispose() {
    disconnect(clearSaved: false);
    super.dispose();
  }
}
