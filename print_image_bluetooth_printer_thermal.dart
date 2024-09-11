import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class PrintImagePage extends StatefulWidget {
  const PrintImagePage({super.key});

  @override
  _PrintImagePageState createState() => _PrintImagePageState();
}

class _PrintImagePageState extends State<PrintImagePage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    bool isConnected = await bluetooth.isConnected ?? false;
    if (!isConnected) {
      _devices = await bluetooth.getBondedDevices();
      setState(() {});
    }
  }

  void _connectToPrinter() async {
    if (_selectedDevice != null) {
      await bluetooth.connect(_selectedDevice!);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    late String message;
    if (pickedFile != null) {
      Uint8List pickedImageBytes = await pickedFile.readAsBytes();
      img.Image? image = img.decodeImage(pickedImageBytes);
      if (image!.width > 384) {
        message = 'Maximal 384 Pixel.';
      } else {
        if (pickedFile.path.endsWith('.png')) {
          imageBytes = await pickedFile.readAsBytes();
          setState(() {});
        } else {
          message = 'Format gambar harus PNG.';
        }
      }
    } else {
      message = 'Gagal memuat gambar.';
    }
    SnackBar snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _printImage() async {
    if (imageBytes != null && _selectedDevice != null) {
      bluetooth.isConnected.then((isConnected) {
        if (isConnected ?? false) {
          bluetooth.printImageBytes(imageBytes!);
        } else {
          _connectToPrinter();
          bluetooth.printImageBytes(imageBytes!);
        }
      });
    } else {
      const snackBar = SnackBar(
        content: Text('No image selected or printer not connected.'),
        behavior: SnackBarBehavior.floating,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      print("No image selected or printer not connected.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Print Image with Bluetooth Printer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageBytes != null) Image.memory(imageBytes!),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            DropdownButton<BluetoothDevice>(
              hint: const Text('Select Printer'),
              value: _selectedDevice,
              items: _devices
                  .map((device) => DropdownMenuItem(
                        value: device,
                        child: Text(device.name ?? ""),
                      ))
                  .toList(),
              onChanged: (device) {
                setState(() {
                  _selectedDevice = device;
                });
                _connectToPrinter();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _printImage,
                      child: const Text('Print Image'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
