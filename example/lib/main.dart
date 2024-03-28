import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(home: MyHome()));
}

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'AAKRITI 2024',
          style: TextStyle(fontFamily: 'Bangers'),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://res.cloudinary.com/dhpnoo9gd/image/upload/v1711624632/AAKRITI/registration_bg_kz9gg0.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://res.cloudinary.com/dhpnoo9gd/image/upload/v1711624552/AAKRITI/logo_mefgwf.png',
                  width: 450, // Adjust width according to your design
                  height: 300, // Adjust height according to your design
                ),
                SizedBox(height: 20),
                Container(
                  width: 200, // Adjust width according to your design
                  height: 50, // Adjust height according to your design
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const QRViewExample(),
                      ));
                    },
                    child: const Text('Scan QR'),
                  ),
                ),
                // Add spacing between the button and the image
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isFlashOn = false;
  bool isScanProcessed = false; // Flag to track if a scan has been processed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Scan QR')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildQrView(context),
                Positioned(
                  top: 16.0,
                  right: 16.0,
                  child: IconButton(
                    icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
                    onPressed: () async {
                      await controller?.toggleFlash();
                      setState(() {
                        isFlashOn = !isFlashOn;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isScanProcessed = false;
              });
            },
            child: const Text('Scan QR'),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    // Create a stream subscription for scannedDataStream
    StreamSubscription<Barcode>? scanSubscription;

    // Listen to the scannedDataStream
    scanSubscription = controller.scannedDataStream.listen((scanData) async {
      if (!isScanProcessed) {
        setState(() {
          isScanProcessed =
              true; // Set the flag to true to prevent further processing
        });

        String? userId = scanData.code;

        var userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          if (userSnapshot.data()?['registeredEvents'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User is allowed to enter.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User is not allowed to enter.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document Does not exist')),
          );
        }

        // Cancel the scanSubscription to prevent further scans
        scanSubscription?.cancel();
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
