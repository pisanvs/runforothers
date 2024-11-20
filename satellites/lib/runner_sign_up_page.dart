import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as im;

import 'package:qr/qr.dart';

class RunnerSignUpPage extends StatefulWidget {
  const RunnerSignUpPage({super.key});

  @override
  State<RunnerSignUpPage> createState() => _RunnerSignUpPageState();
}

class _RunnerSignUpPageState extends State<RunnerSignUpPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController nameController  = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool QROrID = false;

  @override
  void initState() {
    super.initState();
  }

  Future<pw.ImageImage> _renderQrImage(QrCode qrCode) async {
    final qrImage = QrImage(qrCode);

    final image = im.Image(width: qrCode.moduleCount, height: qrCode.moduleCount);
    for (var x = 0; x < qrImage.moduleCount; x++) {
      for (var y = 0; y < qrImage.moduleCount; y++) {
        image.setPixelRgb(x, y, 0xFF, 0xFF, 0xFF);
        if (qrImage.isDark(y, x)) {
          // render a dark square on the canvas
          image.setPixelRgb(x, y, 0x00, 0x00, 0x00);
        }
      }
    }

    return pw.ImageImage(image);
  }

  void signUpRunner() async {
    try {
      final runnerRow = await supabase.from('runners').insert({'name': nameController.text, 'email': emailController.text}).select('id');

      final id = runnerRow[0]['id'];

      if (QROrID) {
        final qrCode = QrCode(2, QrErrorCorrectLevel.H);

        qrCode.addNumeric(id.toString());
        final image = await _renderQrImage(qrCode);
      
        final doc = pw.Document();
        doc.addPage(pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, width: 500, height: 500),
            );
          }
        ));

        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Runner ID: $id'),
              content: Text('Search for the QR Code with the ID on the bottom'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } on PostgrestException catch (err) {
      // TODO: Show exception to user
      print(err.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Runner Name'),
          ),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Runner Email'),
          ),
          TextButton(onPressed: signUpRunner, child: const Text("Sign Up Runner"))
        ],
      ),
    );
  }
}