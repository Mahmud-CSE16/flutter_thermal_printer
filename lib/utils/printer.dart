// ignore_for_file: constant_identifier_names

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class Printer {
  String? address;
  String? name;
  ConnectionType? connectionType;
  bool? isConnected;
  String? vendorId;
  String? productId;
  PaperSize? paperSize;

  Printer({
    this.address,
    this.name,
    this.connectionType,
    this.isConnected,
    this.vendorId,
    this.productId,
    this.paperSize = PaperSize.mm58,
  });

  Printer.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    name =
        json['connectionType'] == 'BLE' ? json['platformName'] : json['name'];
    connectionType = json['connectionType'] == 'BLE'
        ? ConnectionType.BLE
        : ConnectionType.USB;
    isConnected = json['isConnected'];
    vendorId = json['vendorId'];
    productId = json['productId'];
    paperSize = json['paperSize'] == PaperSize.mm58.value? PaperSize.mm58 : json['paperSize'] == PaperSize.mm72.value? PaperSize.mm72 : PaperSize.mm80;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    if (connectionType == ConnectionType.BLE) {
      data['platformName'] = name;
    } else {
      data['name'] = name;
    }
    data['connectionType'] =
        connectionType == ConnectionType.BLE ? 'BLE' : 'USB';
    data['isConnected'] = isConnected;
    data['vendorId'] = vendorId;
    data['productId'] = productId;
    data['paperSize'] = paperSize?.value??1;
    return data;
  }
}

enum ConnectionType {
  BLE,
  USB,
}
