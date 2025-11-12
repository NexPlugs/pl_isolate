import 'dart:isolate';
import 'dart:typed_data';

/// Transferable parse to convert data to transferable and from transferable to data
///
/// Usage:
/// final transferable = TransferableParse.toTransferable(data);
///
/// In isolate communication, you can use this class to convert data to transferable and from transferable to data.
/// This class is used to convert data to transferable and from transferable to data.
class TransferableParse {
  /// Convert data to transferable
  /// [data] is the data to convert to transferable
  /// Returns the transferable data
  static dynamic toTransferable(dynamic data) {
    try {
      if (data is TransferableTypedData) {
        return data;
      } else if (data is ByteBuffer) {
        return TransferableTypedData.fromList([Uint8List.view(data)]);
      } else if (data is Uint8List) {
        return TransferableTypedData.fromList([data]);
      } else {
        return data; // if is normal type return the data
      }
    } catch (_) {
      return data;
    }
  }

  /// Convert transferable to data
  /// [data] is the transferable data to convert to data
  /// Returns the data
  static dynamic fromTransferable(dynamic data) {
    try {
      if (data is TransferableTypedData) {
        return data.materialize().asUint8List();
      }
      return data;
    } catch (_) {
      return data;
    }
  }

  /// Check if the data is transferable
  static bool isTransferable(dynamic data) {
    return data is TransferableTypedData ||
        data is ByteBuffer ||
        data is Uint8List;
  }
}
