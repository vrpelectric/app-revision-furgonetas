// lib/services/pdf_service_simple.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class PDFServiceSimple {
  // Método para cargar el logo VRP desde los assets
  Future<pw.ImageProvider?> _loadVRPLogo() async {
    try {
      print('🔄 Cargando logo VRP desde assets...');
      final ByteData data = await rootBundle.load('lib/assets/icons/logovrp1.png');
      final Uint8List bytes = data.buffer.asUint8List();
      print('✅ Logo VRP cargado correctamente (${bytes.length} bytes)');
      return pw.MemoryImage(bytes);
    } catch (e) {
      print('❌ Error cargando logo VRP: $e');
      return null;
    }
  }

  Future<Uint8List> generateSimplePDF({
    required String vehicleName,
    required String vehiclePlate,
    required String inspectorName,
    required String inspectorRole,
    required String inspectionDate,
  }) async {
    final pdf = pw.Document();

    try {
      print('📄 Generando PDF simple con logo...');
      
      // Cargar el logo VRP
      final vrpLogo = await _loadVRPLogo();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSimpleHeader(vrpLogo),
              pw.SizedBox(height: 20),
              _buildTitle(),
              pw.SizedBox(height: 20),
              _buildSimpleVehicleInfo(vehicleName, vehiclePlate, inspectorName, inspectorRole, inspectionDate),
              pw.SizedBox(height: 20),
              pw.Text(
                'PDF generado correctamente con logo VRP',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                ),
              ),
            ],
          ),
        ),
      );

      print('✅ PDF simple generado correctamente');
      return pdf.save();

    } catch (e) {
      print('❌ Error al generar PDF simple: $e');
      rethrow;
    }
  }

  pw.Widget _buildSimpleHeader(pw.ImageProvider? vrpLogo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue700, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              // Mostrar logo VRP si está disponible, sino el icono circular
              if (vrpLogo != null) ...[
                pw.Container(
                  width: 60,
                  height: 60,
                  child: pw.Image(vrpLogo),
                ),
              ] else ...[
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue700,
                    borderRadius: pw.BorderRadius.circular(25),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'VRP',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              pw.SizedBox(width: 15),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VRP Electric',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.Text(
                    'TECNOLOGIA ELECTRICA',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Text(
        'REVISION PERIODICA FURGONETA',
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue700,
        ),
      ),
    );
  }

  pw.Widget _buildSimpleVehicleInfo(
    String vehicleName,
    String vehiclePlate,
    String inspectorName,
    String inspectorRole,
    String inspectionDate,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: _buildInfoItem('Furgoneta:', vehicleName)),
              pw.Expanded(child: _buildInfoItem('Matricula:', vehiclePlate)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(child: _buildInfoItem('Inspector:', inspectorName)),
              pw.Expanded(child: _buildInfoItem('Cargo:', inspectorRole)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(child: _buildInfoItem('Fecha:', inspectionDate)),
              pw.Expanded(child: _buildInfoItem('Estado:', 'Test con Logo')),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoItem(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
