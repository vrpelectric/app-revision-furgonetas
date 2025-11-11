// lib/services/email_service.dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class EmailService {
  // 📧 CONFIGURACIÓN DE EMAILS DE DESTINO - AHORA MÚLTIPLES DESTINATARIOS
  static const List<String> _destinationEmails = [
    'tcolomar@vrpelectric.com',
    'proveedores@vrpelectric.com',
    'almacenvrp@gmail.com',
    'mroig@vrpelectric.com',
  ];
  static const String _companyName = 'VRP Electric';

  // 🔐 CONFIGURACIÓN SMTP - CONFIGURA TU EMAIL GMAIL AQUÍ
  static const String _senderEmail = 'movilsproba@gmail.com'; // ✅ Tu email
  static const String _senderPassword =
      'mjds rtmf wldr mako'; // ✅ Tu contraseña de aplicación actual
  static const String _senderName = 'VRP Inspeccion de Furgonetas';

  /// Envía el reporte de inspección por email con PDF adjunto a múltiples destinatarios
  Future<bool> sendInspectionReport({
    required Uint8List pdfBytes,
    required String vehicleName,
    required String vehiclePlate,
    required String inspectorName,
    required String inspectorRole,
  }) async {
    try {
      final currentDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      print('📧 Iniciando envío de reporte de inspección...');
      print('📤 De: $_senderEmail');
      print('📥 Para: ${_destinationEmails.join(', ')}');
      print('🚗 Vehículo: $vehicleName - $vehiclePlate');
      print('👤 Inspector: $inspectorName');

      final success = await _sendInspectionEmail(
        pdfBytes: pdfBytes,
        vehicleName: vehicleName,
        vehiclePlate: vehiclePlate,
        inspectorName: inspectorName,
        inspectorRole: inspectorRole,
        currentDate: currentDate,
      );

      if (success) {
        print('✅ ¡Reporte de inspección enviado exitosamente a ${_destinationEmails.length} destinatarios!');
        return true;
      } else {
        print('❌ Error al enviar el reporte');
        return false;
      }
    } catch (e) {
      print('❌ Excepción al enviar reporte: $e');
      return false;
    }
  }

  /// Envía el email usando SMTP directo con PDF como archivo adjunto a múltiples destinatarios
  Future<bool> _sendInspectionEmail({
    required Uint8List pdfBytes,
    required String vehicleName,
    required String vehiclePlate,
    required String inspectorName,
    required String inspectorRole,
    required String currentDate,
  }) async {
    try {
      print('🔧 Configurando servidor SMTP...');

      // Configurar servidor SMTP de Gmail
      final smtpServer = gmail(_senderEmail, _senderPassword);

      // Generar nombre único para el archivo PDF
      final fileName =
          'revision_${vehicleName.replaceAll(' ', '_')}_${_generateFileName(currentDate)}.pdf';

      print('📎 Preparando archivo adjunto: $fileName');

      // Crear el mensaje con archivo adjunto
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        // 👇 AÑADIR MÚLTIPLES DESTINATARIOS
        ..recipients.addAll(_destinationEmails)
        ..subject =
            'Revisión Periódica Furgoneta - $vehicleName ($vehiclePlate) - $_companyName'
        ..html = _buildHtmlEmail(
          vehicleName: vehicleName,
          vehiclePlate: vehiclePlate,
          inspectorName: inspectorName,
          inspectorRole: inspectorRole,
          currentDate: currentDate,
          fileName: fileName,
        );

      // Añadir el PDF como archivo adjunto
      message.attachments = [
        StreamAttachment(
          Stream.fromIterable([pdfBytes]),
          'application/pdf',
          fileName: fileName,
        ),
      ];

      print('📤 Enviando email via SMTP...');
      print('📊 Tamaño del PDF: ${pdfBytes.length} bytes');
      print('📎 Nombre del archivo: $fileName');
      print('👥 Destinatarios: ${_destinationEmails.length}');

      // Enviar el email
      await send(message, smtpServer);

      print('✅ Email enviado exitosamente');
      print('📧 Para: ${_destinationEmails.join(', ')}');
      print('📎 Adjunto: $fileName');

      return true;
    } on MailerException catch (e) {
      print('❌ Error de Mailer: $e');
      for (var p in e.problems) {
        print('   Problema: ${p.code}: ${p.msg}');
        if (p.code == 'AUTH_FAILED') {
          print(
              '   💡 Solución: Verifica tu contraseña de aplicación de Gmail');
          print(
              '   🔑 Contraseña actual configurada: ${_senderPassword.substring(0, 4)}****');
        }
      }
      return false;
    } catch (e) {
      print('❌ Error general: $e');
      return false;
    }
  }

  /// Construye el contenido HTML del email
  String _buildHtmlEmail({
    required String vehicleName,
    required String vehiclePlate,
    required String inspectorName,
    required String inspectorRole,
    required String currentDate,
    required String fileName,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            line-height: 1.6; 
            color: #333; 
            margin: 0; 
            padding: 0; 
            background-color: #f5f5f5;
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background-color: white; 
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .header { 
            background: linear-gradient(135deg, #0082C2 0%, #4DA7D4 100%); 
            color: white; 
            padding: 30px; 
            text-align: center; 
        }
        .header h1 { 
            margin: 0; 
            font-size: 28px; 
            font-weight: 600;
        }
        .header h2 { 
            margin: 10px 0 0 0; 
            font-size: 18px; 
            opacity: 0.9;
            font-weight: 400;
        }
        .content { 
            padding: 30px; 
        }
        .info-section {
            background-color: #f8f9fa;
            border-left: 4px solid #0082C2;
            padding: 20px;
            margin: 20px 0;
            border-radius: 0 8px 8px 0;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-top: 15px;
        }
        .info-item {
            display: flex;
            align-items: center;
        }
        .info-label {
            font-weight: 600;
            color: #0082C2;
            margin-right: 8px;
            min-width: 120px;
        }
        .attachment-box { 
            background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
            border: 2px dashed #0082C2;
            padding: 20px; 
            border-radius: 12px; 
            margin: 20px 0; 
            text-align: center;
        }
        .attachment-icon {
            font-size: 48px;
            color: #0082C2;
            margin-bottom: 10px;
        }
        .vehicle-info {
            background: linear-gradient(135deg, #fff3e0 0%, #ffe0b2 100%);
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
            border-left: 4px solid #ff9800;
        }
        .stats-box {
            background: linear-gradient(135deg, #e8f5e8 0%, #d4edd4 100%);
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
            text-align: center;
        }
        .footer { 
            background-color: #f8f9fa; 
            padding: 25px; 
            text-align: center; 
            border-top: 1px solid #dee2e6;
        }
        .footer-text {
            font-size: 14px; 
            color: #6c757d;
            margin: 5px 0;
        }
        .tech-info {
            background-color: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 8px;
            padding: 15px;
            margin: 20px 0;
        }
        @media (max-width: 600px) {
            .info-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚗 REVISIÓN PERIÓDICA FURGONETA</h1>
            <h2>$_companyName</h2>
        </div>
        
        <div class="content">
            <div class="vehicle-info">
                <div style="font-size: 48px; color: #ff9800; margin-bottom: 10px; text-align: center;">🚐</div>
                <h3 style="margin-top: 0; color: #e65100; text-align: center;">📋 Información del Vehículo</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">🚗 Vehículo:</span>
                        <span>$vehicleName</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">🔢 Matrícula:</span>
                        <span>$vehiclePlate</span>
                    </div>
                </div>
            </div>

            <div class="info-section">
                <h3 style="margin-top: 0; color: #0082C2;">👨‍🔧 Información de la Inspección</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">📅 Fecha:</span>
                        <span>$currentDate</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">👤 Inspector:</span>
                        <span>$inspectorName</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">💼 Cargo:</span>
                        <span>$inspectorRole</span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">🏢 Empresa:</span>
                        <span>$_companyName</span>
                    </div>
                </div>
            </div>

            <div class="attachment-box">
                <div class="attachment-icon">📄</div>
                <h4 style="margin: 0; color: #0082C2;">Reporte Completo de Inspección</h4>
                <p style="margin: 10px 0 0 0; color: #666;">
                    El reporte detallado con todas las verificaciones, fotografías y observaciones está adjunto:<br>
                    <strong style="color: #0082C2;">$fileName</strong>
                </p>
            </div>

            <div class="stats-box">
                <h4 style="margin-top: 0; color: #2e7d32;">📊 Elementos Verificados</h4>
                <p style="margin: 5px 0;">✅ Limpieza y estado general</p>
                <p style="margin: 5px 0;">📋 Documentación y albaranes</p>
                <p style="margin: 5px 0;">⚙️ Herramientas y equipamiento</p>
                <p style="margin: 5px 0;">🔧 Sistema eléctrico y mecánico</p>
                <p style="margin: 5px 0;">📸 Fotografías de evidencia</p>
            </div>

            <div class="tech-info">
                <h4 style="margin-top: 0; color: #856404;">📱 Información Técnica</h4>
                <p style="margin: 5px 0;">• Aplicación: $_companyName Mobile Inspection App v1.0</p>
                <p style="margin: 5px 0;">• Generado automáticamente desde dispositivo móvil</p>
                <p style="margin: 5px 0;">• Sistema de inspección vehicular integrado</p>
                <p style="margin: 5px 0;">• Reporte adjunto en formato PDF con fotografías</p>
                <p style="margin: 5px 0;">• Cumple con protocolo de revisión periódica VRP Electric</p>
            </div>
        </div>

        <div class="footer">
            <p class="footer-text"><strong>📧 Enviado automáticamente desde la aplicación móvil de $_companyName</strong></p>
            <p class="footer-text">🔧 Inspector responsable: $inspectorName | 📱 Sistema de gestión vehicular</p>
            <p class="footer-text"><small>Este email fue generado automáticamente. El archivo PDF contiene el reporte completo de la inspección.</small></p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Genera un nombre de archivo único basado en la fecha
  String _generateFileName(String currentDate) {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  /// Método de prueba
  Future<bool> testEmailConfiguration() async {
    print('🧪 Probando configuración de email para inspección...');
    print('🔑 Email configurado: $_senderEmail');
    print('📧 Destinatarios: ${_destinationEmails.join(', ')}');
    print(
        '🔐 Usando contraseña de aplicación: ${_senderPassword.substring(0, 4)}****');

    // Crear PDF de prueba mínimo pero válido
    final testPdfBytes = Uint8List.fromList([
      0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, // %PDF-1.4
      0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A, // PDF binary comment
    ]);

    return await sendInspectionReport(
      pdfBytes: testPdfBytes,
      vehicleName: 'Furgoneta 001',
      vehiclePlate: 'TEST 123',
      inspectorName: 'Inspector Test',
      inspectorRole: 'Técnico de Prueba',
    );
  }

  /// Muestra las instrucciones de configuración
  static void showConfigurationInstructions() {
    print('''
📋 INSTRUCCIONES PARA CONFIGURAR EMAIL DE INSPECCIÓN CON MÚLTIPLES DESTINATARIOS:

🔐 PASO 1: GENERA UNA CONTRASEÑA DE APLICACIÓN
1. Ve a: https://myaccount.google.com/apppasswords
2. Si no puedes acceder, primero activa la verificación en 2 pasos:
   https://myaccount.google.com/signinoptions/two-step-verification
3. Selecciona "Correo" o "Otra (nombre personalizado)"
4. Escribe: "VRP Electric Inspection App"
5. Google te dará una contraseña como: abcd efgh ijkl mnop

🔑 PASO 2: CONFIGURA LA CONTRASEÑA
1. Abre lib/services/email_service.dart
2. Busca: static const String _senderPassword = 'zhzh eziw bong xpkg';
3. Reemplaza con tu contraseña de aplicación generada por Google
4. Ejemplo: static const String _senderPassword = 'abcd efgh ijkl mnop';

📧 PASO 3: CONFIGURA LOS EMAILS DE DESTINO
1. Busca: static const List<String> _destinationEmails = [
2. Añade o modifica los emails de destino:
   static const List<String> _destinationEmails = [
     'primer.email@gmail.com',
     'segundo.email@gmail.com',
     'tercer.email@gmail.com',  // Puedes añadir más
   ];

📦 PASO 4: VERIFICA LAS DEPENDENCIAS
En pubspec.yaml debe tener:
- mailer: ^6.0.1
- pdf: ^3.10.7
- image_picker: ^1.0.7
- intl: ^0.19.0

🚀 PASO 5: PRUEBA EL ENVÍO
final emailService = EmailService();
await emailService.testEmailConfiguration();

⚠️ IMPORTANTE: 
- NO uses tu contraseña normal de Gmail
- USA SOLO la "Contraseña de aplicación" generada por Google
- El PDF se enviará como archivo adjunto a TODOS los destinatarios
- Incluye todas las fotografías tomadas durante la inspección
- El email se enviará a todos los destinatarios en una sola operación

🔧 CONFIGURACIÓN ACTUAL:
- Email: $_senderEmail
- Destinatarios: ${_destinationEmails.join(', ')}
- Contraseña configurada: ${_senderPassword.substring(0, 4)}****
- Total destinatarios: ${_destinationEmails.length}
    ''');
  }
}