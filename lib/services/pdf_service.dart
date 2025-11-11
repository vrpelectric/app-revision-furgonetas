// lib/services/pdf_service.dart
// VERSIÓN OPTIMIZADA QUE USA IMÁGENES PRE-PROCESADAS
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

class PDFService {
  // Determina si una respuesta es una incidencia según la lógica de la pregunta
  bool _isIncidentAnswer(Map<String, dynamic> question, bool answer) {
    // Si 'isYesAnIncident' es true, SÍ es incidencia
    if (question['isYesAnIncident'] == true) {
      return answer == true;
    } else {
      // Si NO es incidencia, entonces NO es incidencia
      return answer == false;
    }
  }

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

  // Método para determinar el color correcto de la respuesta en el PDF
  PdfColor _getAnswerColorForPDF(Map<String, dynamic> question, bool? answer) {
    if (answer == null) return PdfColors.grey600;
    
    if (question['isYesAnIncident'] == true) {
      // Si SÍ es incidencia: SÍ=rojo, NO=verde
      return answer == true ? PdfColors.red : PdfColors.green;
    } else {
      // Comportamiento normal: SÍ=verde, NO=rojo
      return answer == true ? PdfColors.green : PdfColors.red;
    }
  }

  // 🔧 NUEVO MÉTODO QUE USA IMÁGENES PRE-OPTIMIZADAS
  Future<Uint8List> generateInspectionReportOptimized({
    required String vehicleName,
    required String vehiclePlate,
    required String inspectorName,
    required String inspectorRole,
    required List<Map<String, dynamic>> questions,
    required String inspectionDate,
  }) async {
    final pdf = pw.Document();

    try {
      print('📄 Iniciando generación de PDF con imágenes pre-optimizadas...');
      print('📊 Número de preguntas: ${questions.length}');

      // Cargar el logo VRP al principio
      final vrpLogo = await _loadVRPLogo();

      // 🔧 USAR IMÁGENES YA OPTIMIZADAS (SIN PROCESAMIENTO ADICIONAL)
      final List<List<pw.ImageProvider?>> questionImages = [];
      int optimizedCount = 0;
      
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        List<pw.ImageProvider?> imagesForQuestion = [];
        
        try {
          // 🔧 SI SOPORTA MÚLTIPLES FOTOS, PROCESAR ARRAY
          if (question['supportsMultiplePhotos'] == true) {
            final photos = question['photos'] as List<dynamic>?;
            final optimizedPhotos = question['optimizedPhotosBytes'] as List<dynamic>?;
            
            if (photos != null && photos.isNotEmpty) {
              for (int j = 0; j < photos.length; j++) {
                try {
                  // Usar foto optimizada si existe
                  if (optimizedPhotos != null && j < optimizedPhotos.length && optimizedPhotos[j] != null) {
                    final optimizedBytes = optimizedPhotos[j] as Uint8List;
                    imagesForQuestion.add(pw.MemoryImage(optimizedBytes));
                    optimizedCount++;
                    print('✅ Usando imagen múltiple optimizada ${i + 1}-${j + 1}');
                  } else if (photos[j] != null && photos[j].toString().isNotEmpty) {
                    // Fallback: optimizar si no está pre-optimizada
                    final imageFile = File(photos[j]);
                    if (await imageFile.exists()) {
                      final optimizedImage = await _optimizeImageForPDF(imageFile);
                      if (optimizedImage != null) {
                        imagesForQuestion.add(pw.MemoryImage(optimizedImage));
                        print('✅ Imagen múltiple ${i + 1}-${j + 1} optimizada como fallback');
                      } else {
                        print('⚠️ No se pudo optimizar imagen múltiple ${i + 1}-${j + 1}');
                      }
                    } else {
                      print('⚠️ Archivo de imagen múltiple ${i + 1}-${j + 1} no existe: ${photos[j]}');
                    }
                  }
                } catch (e) {
                  print('❌ Error procesando imagen múltiple ${i + 1}-${j + 1}: $e');
                }
              }
            }
          } else {
            // 🔧 PROCESAMIENTO NORMAL PARA FOTO INDIVIDUAL
            if (question['optimizedPhotoBytes'] != null) {
              final optimizedBytes = question['optimizedPhotoBytes'] as Uint8List;
              imagesForQuestion.add(pw.MemoryImage(optimizedBytes));
              optimizedCount++;
              print('✅ Usando imagen optimizada ${i + 1}');
            } else if (question['photo'] != null && question['photo'].toString().isNotEmpty) {
              // 🔧 FALLBACK: Optimizar si no está pre-optimizada
              final imageFile = File(question['photo']);
              if (await imageFile.exists()) {
                final optimizedImage = await _optimizeImageForPDF(imageFile);
                if (optimizedImage != null) {
                  imagesForQuestion.add(pw.MemoryImage(optimizedImage));
                  print('✅ Imagen ${i + 1} optimizada como fallback');
                } else {
                  print('⚠️ No se pudo optimizar imagen ${i + 1}');
                }
              } else {
                print('⚠️ Archivo de imagen ${i + 1} no existe: ${question['photo']}');
              }
            }
          }
        } catch (e) {
          print('❌ Error procesando imagen ${i + 1}: $e');
        }
        
        questionImages.add(imagesForQuestion);
      }
      
      print('🚀 ${optimizedCount} imágenes pre-optimizadas utilizadas');
      print('📈 Velocidad de generación mejorada significativamente');
      
      // Verificación de seguridad
      if (questionImages.length != questions.length) {
        print('❌ ERROR CRÍTICO: Desajuste en el número de elementos');
        print('   - Preguntas: ${questions.length}');
        print('   - Imágenes: ${questionImages.length}');
        
        while (questionImages.length < questions.length) {
          questionImages.add(<pw.ImageProvider?>[]);
          print('🔧 Añadido array vacío para igualar las listas');
        }
        
        if (questionImages.length > questions.length) {
          questionImages.removeRange(questions.length, questionImages.length);
          print('🔧 Truncado la lista de imágenes');
        }
        
        print('✅ Listas ajustadas - Preguntas: ${questions.length}, Imágenes: ${questionImages.length}');
      }

      // Dividir preguntas en grupos de 3 por página
      final List<List<Map<String, dynamic>>> questionGroups = [];
      final List<List<List<pw.ImageProvider?>>> imageGroups = [];
      
      const int questionsPerPage = 3;
      
      if (questions.isNotEmpty) {
        for (int i = 0; i < questions.length; i += questionsPerPage) {
          final endIndex = (i + questionsPerPage < questions.length) 
              ? i + questionsPerPage 
              : questions.length;
          
          questionGroups.add(questions.sublist(i, endIndex));
          imageGroups.add(questionImages.sublist(i, endIndex));
        }
      }

      print('📑 Dividiendo en ${questionGroups.length} páginas de preguntas');
      print('📝 Preguntas por página: ${questionGroups.map((group) => group.length).toList()}');

      // Páginas con preguntas
      for (int groupIndex = 0; groupIndex < questionGroups.length; groupIndex++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (groupIndex == 0) ...[
                  _buildHeader(vrpLogo),
                  pw.SizedBox(height: 15),
                  _buildTitle(),
                  pw.SizedBox(height: 15),
                  _buildVehicleInfo(vehicleName, vehiclePlate, inspectorName, inspectorRole, inspectionDate, questions),
                  pw.SizedBox(height: 15),
                ] else ...[
                  _buildSimpleHeader(),
                  pw.SizedBox(height: 15),
                ],
                
                pw.Expanded(
                  child: _buildOptimizedQuestionsSection(
                    questionGroups[groupIndex], 
                    imageGroups[groupIndex], 
                    groupIndex + 1, 
                    questionGroups.length
                  ),
                ),
                
                _buildFooterInfo(groupIndex + 1, questionGroups.length + 1),
              ],
            ),
          ),
        );
      }

      // Página final con resumen
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSimpleHeader(),
              pw.SizedBox(height: 20),
              _buildSummary(questions),
              pw.Spacer(),
              _buildFooterInfo(questionGroups.length + 1, questionGroups.length + 1),
            ],
          ),
        ),
      );

      print('✅ PDF generado correctamente con imágenes pre-optimizadas');
      return pdf.save();

    } catch (e) {
      print('❌ Error al generar PDF optimizado: $e');
      
      // Fallback al método básico
      return _generateBasicPDF(
        vehicleName: vehicleName,
        vehiclePlate: vehiclePlate,
        inspectorName: inspectorName,
        inspectorRole: inspectorRole,
        questions: questions,
        inspectionDate: inspectionDate,
      );
    }
  }

  // 🔧 MÉTODO ORIGINAL MANTENIDO PARA COMPATIBILIDAD
  Future<Uint8List> generateInspectionReport({
    required String vehicleName,
    required String vehiclePlate,
    required String inspectorName,
    required String inspectorRole,
    required List<Map<String, dynamic>> questions,
    required String inspectionDate,
  }) async {
    // Redirigir al método optimizado
    return generateInspectionReportOptimized(
      vehicleName: vehicleName,
      vehiclePlate: vehiclePlate,
      inspectorName: inspectorName,
      inspectorRole: inspectorRole,
      questions: questions,
      inspectionDate: inspectionDate,
    );
  }

  Future<Uint8List?> _optimizeImageForPDF(File imageFile) async {
    try {
      final originalBytes = await imageFile.readAsBytes();
      
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) return null;

      // Resolución más alta para mejor calidad
      const int maxWidth = 500;
      const int maxHeight = 400;
      
      if (image.width > maxWidth || image.height > maxHeight) {
        double aspectRatio = image.width / image.height;
        int newWidth, newHeight;
        
        if (aspectRatio > 1) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
        
        // Aplicar filtro anti-aliasing previo al resize
        if (image.width > newWidth * 2 || image.height > newHeight * 2) {
          image = img.gaussianBlur(image, radius: 1);
        }
        
        // Redimensionar con máxima calidad
        image = img.copyResize(
          image, 
          width: newWidth, 
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
        
        print('📐 Imagen redimensionada a ${newWidth}x${newHeight} con filtros de calidad');
      }

      // Compresión de máxima calidad
      final compressedBytes = img.encodeJpg(image, quality: 95);
      
      print('📦 Tamaño original: ${originalBytes.length} bytes');
      print('📦 Tamaño optimizado: ${compressedBytes.length} bytes');
      print('📉 Reducción: ${((1 - compressedBytes.length / originalBytes.length) * 100).toStringAsFixed(1)}%');
      
      return Uint8List.fromList(compressedBytes);
      
    } catch (e) {
      print('❌ Error optimizando imagen: $e');
      return null;
    }
  }

  pw.Widget _buildOptimizedQuestionsSection(
    List<Map<String, dynamic>> questions,
    List<List<pw.ImageProvider?>> imageGroups,
    int pageNumber,
    int totalPages,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CHECKLIST DE REVISIÓN - Página $pageNumber de $totalPages',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 15),
        
        pw.Expanded(
          child: pw.Column(
            children: questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              
              // Verificación de seguridad para evitar RangeError
              List<pw.ImageProvider?> imagesForQuestion = [];
              if (index < imageGroups.length) {
                imagesForQuestion = imageGroups[index];
              } else {
                print('⚠️ Advertencia: Índice $index fuera del rango de imágenes (${imageGroups.length})');
              }
              
              return _buildQuestionCard(question, imagesForQuestion);
            }).toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildQuestionCard(Map<String, dynamic> question, List<pw.ImageProvider?> images) {
    final answer = question['answer'];
    final observations = question['observations'] ?? '';
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            question['question'],
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Si hay múltiples imágenes, mostrar en grid
              if (images.isNotEmpty) ...[
                pw.Container(
                  width: 150,
                  child: pw.Column(
                    children: [
                      if (images.length == 1) ...[
                        // Una sola imagen
                        pw.Container(
                          width: 150,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300, width: 1),
                            borderRadius: pw.BorderRadius.circular(6),
                            color: PdfColors.white,
                          ),
                          child: pw.ClipRRect(
                            horizontalRadius: 6,
                            verticalRadius: 6,
                            child: pw.Image(
                              images[0]!, 
                              fit: pw.BoxFit.contain,
                              alignment: pw.Alignment.center,
                            ),
                          ),
                        ),
                      ] else if (images.length > 1) ...[
                        // Múltiples imágenes en grid
                        pw.Text(
                          '${images.length} fotos del equipamiento:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: images.take(4).map((image) => // Máximo 4 imágenes por espacio
                            pw.Container(
                              width: 70,
                              height: 50,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                                borderRadius: pw.BorderRadius.circular(4),
                                color: PdfColors.white,
                              ),
                              child: pw.ClipRRect(
                                horizontalRadius: 4,
                                verticalRadius: 4,
                                child: pw.Image(
                                  image!, 
                                  fit: pw.BoxFit.contain,
                                  alignment: pw.Alignment.center,
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                        if (images.length > 4) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '+ ${images.length - 4} fotos más',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 15),
              ],
              
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'Respuesta: ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (answer == true) ...[
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: _getAnswerColorForPDF(question, answer),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              'SÍ',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (answer == false) ...[
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: _getAnswerColorForPDF(question, answer),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              'NO',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else ...[
                          pw.Text(
                            'Sin responder',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey600,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    if (observations.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Observaciones:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        observations,
                        style: const pw.TextStyle(fontSize: 9),
                        maxLines: 3,
                      ),
                    ],
                    
                    // Mostrar fecha de caducidad del extintor debajo de la pregunta
                    if (question['question'].toString().toLowerCase().contains('extintor')) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        question['expiryDate'] != null
                          ? 'Fecha de caducidad del extintor: ' +
                            (question['expiryDate'] is DateTime
                              ? DateFormat('dd/MM/yyyy').format(question['expiryDate'])
                              : question['expiryDate'].toString())
                          : 'Fecha de caducidad del extintor: No indicada',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                    // Mostrar respuesta de texto si existe (p.ej. equipos de medida / seguridad)
                    if ((question['textAnswer'] ?? '').toString().trim().isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Respuesta (texto):',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        (question['textAnswer'] ?? '').toString(),
                        style: const pw.TextStyle(fontSize: 9),
                        maxLines: 5,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generateBasicPDF({
    required String vehicleName,
    required String vehiclePlate,
    required String inspectorName,
    required String inspectorRole,
    required List<Map<String, dynamic>> questions,
    required String inspectionDate,
  }) async {
    print('🔄 Generando PDF básico sin imágenes...');
    
    final pdf = pw.Document();
    
    // Cargar el logo VRP
    final vrpLogo = await _loadVRPLogo();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(vrpLogo),
            pw.SizedBox(height: 20),
            _buildTitle(),
            pw.SizedBox(height: 20),
            _buildVehicleInfo(vehicleName, vehiclePlate, inspectorName, inspectorRole, inspectionDate, questions),
            pw.SizedBox(height: 20),
            _buildSimpleQuestionsTable(questions),
            pw.SizedBox(height: 20),
            _buildSummary(questions),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.ImageProvider? vrpLogo) {
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
                  width: 50,
                  height: 50,
                  child: pw.Image(vrpLogo),
                ),
              ] else ...[
                pw.Container(
                  width: 40,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue700,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'VRP',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VRP Electric',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.Text(
                    'TECNOLOGÍA ELÉCTRICA',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Text(
            '',
            style: pw.TextStyle(fontSize: 30),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSimpleHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue700, width: 1)),
      ),
      child: pw.Center(
        child: pw.Text(
          'VRP Electric - Revisión Periódica Furgoneta',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Text(
        'REVISIÓN PERIÓDICA FURGONETA',
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue700,
        ),
      ),
    );
  }

  pw.Widget _buildVehicleInfo(
    String vehicleName,
    String vehiclePlate,
    String inspectorName,
    String inspectorRole,
    String inspectionDate,
    List<Map<String, dynamic>> questions,
  ) {
    // Buscar fecha de ITV en las preguntas
    String itvExpiryText = '_______________';
    try {
      final itvQuestion = questions.firstWhere(
        (q) => q['requiresItvDate'] == true,
        orElse: () => <String, dynamic>{},
      );
      
      if (itvQuestion.isNotEmpty && itvQuestion['itvExpiry'] != null) {
        final DateTime itvDate = itvQuestion['itvExpiry'];
        itvExpiryText = DateFormat('dd/MM/yyyy').format(itvDate);
        
        final bool isExpired = itvDate.isBefore(DateTime.now());
        if (isExpired) {
          itvExpiryText += ' (VENCIDA)';
        }
        print('✅ Fecha ITV encontrada: $itvExpiryText');
      } else {
        print('⚠️ No se encontró fecha de ITV en las preguntas');
      }
    } catch (e) {
      print('❌ Error buscando fecha ITV: $e');
      itvExpiryText = '_______________';
    }
    
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
              pw.Expanded(child: _buildInfoItem('Matrícula:', vehiclePlate)),
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
              pw.Expanded(child: _buildInfoItem('Caducidad ITV:', itvExpiryText)),
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
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSimpleQuestionsTable(List<Map<String, dynamic>> questions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CHECKLIST DE REVISIÓN',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('PREGUNTA'),
                _buildTableHeader('SÍ'),
                _buildTableHeader('NO'),
                _buildTableHeader('OBSERVACIONES'),
              ],
            ),
            ...questions.map((question) => _buildSimpleQuestionRow(question)).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.TableRow _buildSimpleQuestionRow(Map<String, dynamic> question) {
    final answer = question['answer'];
    final observations = question['observations'] ?? '';
    
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            question['question'],
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Center(
            child: answer == true
                ? pw.Text('✓', style: pw.TextStyle(fontSize: 14, color: _getAnswerColorForPDF(question, true)))
                : pw.Text(''),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Center(
            child: answer == false
                ? pw.Text('✗', style: pw.TextStyle(fontSize: 14, color: _getAnswerColorForPDF(question, false)))
                : pw.Text(''),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            observations.isNotEmpty ? observations : '-',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummary(List<Map<String, dynamic>> questions) {
    final totalQuestions = questions.length;
    
    // Contar incidencias según la nueva lógica
    int correctAnswers = 0;
    int incidents = 0;
    
    for (final question in questions) {
      // Priorizar preguntas con botones SÍ/NO cuando se haya respondido
      final bool? answer = question['answer'] as bool?;

      if (answer != null) {
        final isIncident = _isIncidentAnswer(question, answer);
        if (isIncident) {
          incidents++;
        } else {
          correctAnswers++;
        }
        continue;
      }

      // Si no hay respuesta (null) y la pregunta no tiene botones SÍ/NO
      // considerarla correcta en el resumen cuando tenga el input esperado.
      // - Para preguntas con múltiples fotos: al menos 1 foto -> correcto
      // - Para preguntas con foto simple requerida: photo u optimizedPhotoBytes -> correcto
      // - Para preguntas que piden fecha ITV/extintor: si existe la fecha -> correcto

      // Multiples fotos
      if (question['supportsMultiplePhotos'] == true) {
        final photos = question['photos'] as List<dynamic>?;
        if (photos != null && photos.isNotEmpty) {
          correctAnswers++;
          continue;
        }
      }

      // Foto simple (optimizada o no)
      if (question['requiresPhoto'] == true) {
        if ((question['optimizedPhotoBytes'] != null) || (question['photo'] != null && question['photo'].toString().isNotEmpty)) {
          correctAnswers++;
          continue;
        }
      }

      // Fecha ITV / Extintor
      if (question['requiresItvDate'] == true && question['itvExpiry'] != null) {
        correctAnswers++;
        continue;
      }
      if (question['requiresExpiryDate'] == true && question['expiryDate'] != null) {
        correctAnswers++;
        continue;
      }

      // Texto-only answers
      if (question['requiresTextAnswer'] == true) {
        final text = (question['textAnswer'] as String?) ?? '';
        if (text.trim().isNotEmpty) {
          correctAnswers++;
          continue;
        }
      }

      // Si la pregunta requiere texto solo cuando la respuesta es SÍ
      if (question['requiresTextIfYes'] == true) {
        if (answer == true) {
          final text = (question['textAnswer'] as String?) ?? '';
          if (text.trim().isNotEmpty) {
            // SÍ con detalle -> correcto (no es incidencia salvo que isYesAnIncident indique lo contrario)
            final isIncident = question['isYesAnIncident'] == true;
            if (isIncident) {
              incidents++;
            } else {
              correctAnswers++;
            }
            continue;
          }
        } else if (answer == false) {
          // Respuesta NO -> según lógica normal, contabilizar como correcto o incidencia
          final isIncident = _isIncidentAnswer(question, false);
          if (isIncident) {
            incidents++;
          } else {
            correctAnswers++;
          }
          continue;
        }
      }

      // Si no cumple ninguna de las condiciones anteriores, no se cuenta como correcto
      // y tampoco como incidencia (se deja fuera del conteo).
    }
    
    // Calcular fotos considerando múltiples imágenes
   
    
    
    // Buscar información de ITV para el resumen
    final itvQuestion = questions.firstWhere(
      (q) => q['requiresItvDate'] == true,
      orElse: () => <String, dynamic>{},
    );
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMEN DE LA REVISIÓN',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 10),
          
          // Sección: Respuestas de texto recogidas (p.ej. equipos de medida / seguridad)
          pw.SizedBox(height: 8),
          pw.Text(
            'Respuestas en texto:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: questions
                .where((q) => (q['textAnswer'] ?? '').toString().trim().isNotEmpty)
                .map((q) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            q['question'],
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            (q['textAnswer'] ?? '').toString(),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
          pw.SizedBox(height: 10),

          // Información de ITV en el resumen
          if (itvQuestion.isNotEmpty && itvQuestion['itvExpiry'] != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.orange300),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'ITV:',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange700,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Vence el ${DateFormat('dd/MM/yyyy').format(itvQuestion['itvExpiry'])}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.orange800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Spacer(),
                  if (itvQuestion['itvExpiry'].isBefore(DateTime.now())) ...[
                    pw.Text(
                      'VENCIDA',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.red,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    pw.Text(
                      'EN VIGOR',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.green,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],
          
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total', '$totalQuestions', PdfColors.blue),
              _buildSummaryItem('Correctos', '$correctAnswers', PdfColors.green),
              _buildSummaryItem('Incidencias', '$incidents', PdfColors.red),
            ],
          ),
          pw.SizedBox(height: 10),
          
          
          
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: incidents > 0 ? PdfColors.red100 : PdfColors.green100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              incidents > 0
                  ? 'ATENCIÓN: Se han detectado $incidents incidencia(s) que requieren atención.'
                  : 'EXCELENTE: La furgoneta ha pasado todas las verificaciones correctamente.',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: incidents > 0 ? PdfColors.red : PdfColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 28,
          height: 28,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(14),
          ),
          child: pw.Center(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooterInfo(int currentPage, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'VRP Electric - Sistema de Revisión Optimizado',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página $currentPage de $totalPages - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}