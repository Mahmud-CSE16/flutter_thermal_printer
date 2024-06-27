// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

  List<Printer> printers = [];

  StreamSubscription<List<Printer>>? _devicesStreamSubscription;
  bool bluetoothON = false;

  // Get Printer List
  void startScan() async {
    FlutterBluePlus.adapterState.listen((event) {
      if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
        bluetoothON = false;
        log("BLUETOOTH IS OFF");
      } else {
        bluetoothON = true;
        log("BLUETOOTH IS ON");
      }
    });
    _devicesStreamSubscription?.cancel();
    await _flutterThermalPrinterPlugin.getPrinters();
    _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream.listen((List<Printer> event) {
      log(event.map((e) => e.name).toList().toString());
      setState(() {
        printers = event;
        printers.removeWhere((element) => element.name == null || element.name == '');
      });
    });
  }

  @override
  void initState() {
    super.initState();
    //*******Added listener**********//
    _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream.listen((List<Printer> event) {
      log(event.map((e) => e.name).toList().toString());
      setState(() {
        printers = event;
        printers.removeWhere((element) => element.name == null || element.name == '');
      });
    });
  }

  void getUsbDevices() async {
    await _flutterThermalPrinterPlugin.getUsbDevices();
  }

  img.Image getGrayscaleImage({required Uint8List imageBytes, int? height, int width = 385}) {
    final decodedImage = img.decodeImage(imageBytes)!;

    img.Image thumbnail = img.copyResize(decodedImage, height: height ?? decodedImage.height);
    img.Image originalImg = img.copyResize(decodedImage, height: height ?? decodedImage.height);
    img.fill(originalImg, color: img.ColorRgb8(255, 255, 255));
    var padding = (originalImg.width - thumbnail.width) / 2;

    //insert the image inside the frame and center it
    img.compositeImage(originalImg, thumbnail, dstX: padding.toInt());

    // convert image to grayscale
    return img.grayscale(originalImg);
  }

  void testPrint(index) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    final receiptItemsImage = getGrayscaleImage(imageBytes: await getReceiptImage());
    bytes += generator.imageRaster(receiptItemsImage, align: PosAlign.center);
    bytes += generator.qrcode("https://www.zatiq.com/", size: QRSize.Size8, align: PosAlign.center);

    // bytes += generator.text("Sunil Kumar",
    //     styles: const PosStyles(
    //       bold: true,
    //       height: PosTextSize.size2,
    //       width: PosTextSize.size2,
    //     ));
    // bytes += generator.cut();

    await _flutterThermalPrinterPlugin.printData(
      printers[index],
      bytes,
      longData: true,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                startScan();
                // getUsbDevices();
              },
              child: const Text('Get Printers'),
            ),
            // if(printers.isEmpty) Container(
            //   child: Text(),
            // ),

            if (!bluetoothON) const Text("Currently, your bluetooth is off"),

            Expanded(
              child: ListView.builder(
                itemCount: printers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      if (printers[index].isConnected ?? false) {
                        await _flutterThermalPrinterPlugin.disconnect(printers[index]);
                      } else {
                        final isConnected = await _flutterThermalPrinterPlugin.connect(printers[index]);
                        log("Devices: $isConnected");
                      }
                    },
                    title: Text(printers[index].name ?? 'No Name'),
                    subtitle: Text("VendorId: ${printers[index].address} - Connected: ${printers[index].isConnected}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.connect_without_contact),
                      onPressed: () async {
                        testPrint(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<Uint8List> getReceiptImage() async {
    return ScreenshotController().captureFromWidget(receiptWidget(),context:context);
  }
  Widget receiptWidget() {
    return const SizedBox(
       width: 125,
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "FLUTTER THERMAL PRINTER",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Hello World",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "This is a test receipt",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
