// lib/screens/inspection/inspection_flow_screen.dart
// VERSIÓN CON SISTEMA DE ETIQUETAS PERSONALIZADAS Y SCROLL AUTOMÁTICO
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../services/pdf_service.dart';
import '../../services/email_service.dart';

class InspectionFlowScreen extends StatefulWidget {
  final String vehicleName;
  final String vehiclePlate;
  final String inspectorName;
  final String inspectorRole;

  const InspectionFlowScreen({
    super.key,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.inspectorName,
    required this.inspectorRole,
  });

  @override
  State<InspectionFlowScreen> createState() => _InspectionFlowScreenState();
}

class _InspectionFlowScreenState extends State<InspectionFlowScreen> {
  int _currentQuestionIndex = 0;
  final PageController _pageController = PageController();
  bool _isGeneratingReport = false;
  bool _isOptimizingImage = false;
  
  // 📜 CONTROLADOR DE SCROLL PARA ASEGURAR QUE SIEMPRE SE VEA DESDE ARRIBA
  final ScrollController _scrollController = ScrollController();
  
  // ✅ CONTROLADORES INDIVIDUALES PARA CADA PREGUNTA
  List<TextEditingController> _observationControllers = [];
  // Controladores para respuestas de texto específicas (p.ej. unidades/modelo)
  List<TextEditingController> _textAnswerControllers = [];

  // 🏷️ LISTA MEJORADA CON SISTEMA DE ETIQUETAS PERSONALIZADAS
  final List<Map<String, dynamic>> _questions = [
    {
      'question': '¿LA CABINA DE LA FURGONETA ESTÁ LIMPIA?',
      'category': 'Limpieza',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
      'observations': '',
      'tags': [
      
      ],
    },
    {
      'question': '¿LA FURGONETA TIENE LA LUNA DELANTERA LIMPIA?',
      'category': 'Limpieza',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
      'observations': '',
      'tags': [
        
      ],
    },
    {
      'question': '¿LA FURGONETA MARCA ALGUNA AVERÍA, FALTA ACEITE O LIQUIDO REFRIGERANTE?',
      'category': 'Estado General',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
      'observations': '',
      'isYesAnIncident': true, // SÍ es una incidencia (rojo)
      'tags': [
        {
          'text': 'Revisar luces del tablero con la furgoneta en marcha',
          'color': Colors.red,
          'icon': Icons.search,
        },
        {
          'text': 'Si hay avería, anotar que averia sale en observaciones',
          'color': const Color.fromARGB(255, 233, 112, 13),
          'icon': Icons.error_outline,
        }
      ],
    },
    
    {
      'question': '¿HAY ALBARANES DE MATERIAL EN LA FURGONETA?',
      'category': 'Documentación',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
      'observations': '',
      'requiresPhotoIfTrue': true, // Requiere foto solo si la respuesta es SÍ
      'isYesAnIncident': true, // SÍ es una incidencia (rojo)
      'tags': [
        {
          'text': 'si los hay, entregar en alamacén en menos de 24h',
          'color': const Color.fromARGB(255, 241, 137, 17),
          'icon': Icons.folder_outlined,
        }
      ],
    },
    {
      'question': '¿LA ITV ESTÁ EN VIGOR?',
      'category': 'Documentación',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
      'observations': '',
      'itvExpiry': null,
      'requiresItvDate': true,
      'tags': [
    
      ],
    },
    {
      'question': 'QUE HERRAMIENTAS MANUALES LLEVAS EN LA FURGONETA?',
      'category': 'Herramientas',
      // Esta pregunta no usa botones SÍ/NO, solo permite añadir múltiples fotos
      'answer': null,
      'photo': null,
      'photos': [], // para múltiples fotos
      'optimizedPhotosBytes': [],
      'supportsMultiplePhotos': true,
  // No mostrar botones SÍ/NO para esta pregunta (solo fotos/observaciones)
  'showAnswerButtons': false,
      'requiresPhoto': true, // al menos una foto requerida
      'observations': '',
      'tags': [
        {
          'text': 'Hacer foto de todas las herramientas manuales',
          'color': const Color.fromARGB(255, 233, 131, 14),
          'icon': Icons.build,
        },
        {
          'text': 'Indicar en Observaciones que herramientas llevas',
          'color': Colors.blue,
          'icon': Icons.auto_awesome,
        }
      ],
    },
    {
      'question': 'QUE EQUIPOS DE MEDIDA LLEVAS EN LA FURGONETA?',
      'category': 'Herramientas',
      // Solo texto: solicitar unidades y modelo (p.ej. 'Multímetro - Fluke 87V')
      'answer': null,
      'photo': null,
      'textAnswer': '',
  'requiresTextAnswer': true,
  // indicar que es pregunta solo texto (no mostrar botones SÍ/NO)
  'showAnswerButtons': false,
      'requiresPhoto': false,
      'observations': '',
      'tags': [
        {
          'text': 'Indicar modelo Y unidades, p.ej. "Multímetro - 3"',
          'color': Colors.blue,
          'icon': Icons.straighten,
        }
      ],
    },
    {
      'question': 'QUE EQUIPOS DE SEGURIDAD LLEVAS EN LA FURGONETA?',
      'category': 'Seguridad',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
      'observations': '',
  // Esta pregunta será solo texto: no mostrar botones SÍ/NO
  'showAnswerButtons': false,
  // No requiere foto para esta pregunta
  'requiresPhoto': false,
  // Convertir a pregunta solo texto (detalle obligatorio para marcar como completada)
  'requiresTextAnswer': true,
      'textAnswer': '',
      'tags': [
        {
          'text': 'Indicar qué equipos: Guantes aislantes, Gafas de seguridad, Casco de seguridad, Calzado de seguridad, Arnés de seguridad...',
          'color': Colors.red,
          'icon': Icons.shield,
        }
      ],
    },
    {
      'question': '¿LA PRESIÓN DE LAS RUEDAS ES LA ADECUADA?',
      'category': 'Mantenimiento',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
      'observations': '',
      'requiresPhoto': false, // No requiere foto
      'tags': [
        {
          'text': 'Verificar presión visualmente o con medidor',
          'color': Colors.teal,
          'icon': Icons.speed,
        },
        {
          'text': 'Buscar desgaste irregular o daños',
          'color': Colors.orange,
          'icon': Icons.visibility,
        }
      ],
    },
    {
      'question': '¿LA FURGONETA LLEVA LA RUEDA DE REPUESTO, TRIANGULOS DE EMERGENCIA, GATO Y CHALECOS?',
      'category': 'Equipamiento',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
  'photos': [], // Array para múltiples fotos
  'optimizedPhotosBytes': [], // Array para múltiples fotos optimizadas
      'observations': '',
  'supportsMultiplePhotos': true, // Identificador para múltiples fotos
  'showAnswerButtons': true, // Mostrar botones SÍ/NO además de permitir múltiples fotos
  'requiredPhotosCount': 4, // Requiere exactamente 4 fotos como mínimo
  'requiresPhoto': true,
      'tags': [
        {
          'text': 'Foto de rueda de repuesto',
          'color': Colors.blue,
          'icon': Icons.tire_repair,
        },
        {
          'text': 'Foto de triángulos de emergencia',
          'color': Colors.orange,
          'icon': Icons.warning,
        },
        {
          'text': 'Foto del gato',
          'color': Colors.green,
          'icon': Icons.build,
        },
        {
          'text': 'Foto de chaleco conductor y acompañante',
          'color': const Color.fromARGB(255, 233, 236, 16),
          'icon': Icons.safety_check,
        }
      ],
    },
      {
  'question': '¿EL EXTINTOR ESTÁ EN SU LUGAR Y EN BUEN ESTADO?',
  'category': 'Seguridad',
  'answer': null,
  'photo': null,
  'optimizedPhotoBytes': null,
  'observations': '',
  'expiryDate': null, // Campo para fecha de caducidad del extintor
  'requiresExpiryDate': true, // Flag para mostrar campo de fecha del extintor
  'requiresPhoto': true, // Requiere foto obligatoria
  
  'tags': [
          {
            'text': 'Verificar fecha de caducidad y estado físico',
            'color': Colors.red,
            'icon': Icons.fire_extinguisher,
          }
        ],
      },
      {
        'question': '¿EL BOTIQUÍN ESTÁ COMPLETO Y EN BUEN ESTADO?',
        'category': 'Seguridad',
        'answer': null,
        'photo': null,
        'optimizedPhotoBytes': null,
        'observations': '',
    'requiresPhoto': true, // Requiere foto obligatoria
        'tags': [
          {
            'text': 'Revisar que tenga todos los elementos básicos',
            'color': Colors.green,
            'icon': Icons.medical_services,
          }
        ],
      },
    {
      'question': '¿FUNCIONAN TODAS LAS LUCES E INTERMITENTES?',
      'category': 'Sistema Eléctrico',
      'answer': null,
      'photo': null,
      'optimizedPhotoBytes': null,
      'observations': '',
      'requiresPhoto': false, // No requiere foto
      'tags': [
        {
          'text': '💡 Probar luces altas, bajas, freno y reversa',
          'color': const Color.fromARGB(255, 233, 141, 37),
          'icon': Icons.lightbulb,
        },
        {
          'text': '🔄 Verificar intermitentes delanteros y traseros',
          'color': Colors.green,
          'icon': Icons.rotate_right,
        },
        {
          'text': '🚨 Incluir luces de emergencia',
          'color': Colors.red,
          'icon': Icons.emergency,
        }
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    print('🚀 Iniciando InspectionFlowScreen...');
    print('📊 Total de preguntas: ${_questions.length}');
    
    // ✅ CREAR CONTROLADORES INDIVIDUALES
    _observationControllers = List.generate(
      _questions.length,
      (index) => TextEditingController(text: _questions[index]['observations']),
    );

    // Controladores para respuestas de texto (si existen preguntas de texto)
    _textAnswerControllers = List.generate(
      _questions.length,
      (index) => TextEditingController(text: _questions[index]['textAnswer'] ?? ''),
    );

    // ✅ LISTENERS PARA SINCRONIZAR
    for (int i = 0; i < _observationControllers.length; i++) {
      _observationControllers[i].addListener(() {
        if (mounted) {
          _questions[i]['observations'] = _observationControllers[i].text;
        }
      });
    }

    // Listeners para sincronizar las respuestas de texto con el modelo
    for (int i = 0; i < _textAnswerControllers.length; i++) {
      _textAnswerControllers[i].addListener(() {
        if (!mounted) return;
        // Siempre sincronizar el modelo
        _questions[i]['textAnswer'] = _textAnswerControllers[i].text;
        // Si el usuario está editando la pregunta visible, forzar rebuild
        if (mounted && _currentQuestionIndex == i) {
          setState(() {});
        }
      });
    }
    
    print('✅ Controladores inicializados: ${_observationControllers.length}');
  }

  @override
  void dispose() {
    print('🧹 Limpiando recursos...');
    for (var controller in _observationControllers) {
      controller.dispose();
    }
    for (var controller in _textAnswerControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    _scrollController.dispose(); // 📜 LIMPIAR SCROLL CONTROLLER
    super.dispose();
  }

  // 🔧 MÉTODO: Optimizar imagen inmediatamente
  Future<Uint8List?> _optimizeImageImmediate(File imageFile) async {
    try {
      print('🔧 Optimizando imagen inmediatamente...');
      final originalBytes = await imageFile.readAsBytes();
      
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) {
        print('❌ No se pudo decodificar la imagen');
        return null;
      }

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
        
        print('📐 Imagen redimensionada a ${newWidth}x${newHeight}');
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

  // 🔧 MÉTODO: Determinar si una pregunta requiere foto
  bool _shouldShowPhoto(Map<String, dynamic> question) {
    // Si tiene requiresPhoto = false, nunca requiere foto
    if (question['requiresPhoto'] == false) {
      return false;
    }
    
    // Si tiene requiresPhotoIfTrue = true, solo requiere foto si la respuesta es SÍ
    if (question['requiresPhotoIfTrue'] == true) {
      return question['answer'] == true;
    }
    
    // Si soporta múltiples fotos, siempre mostrar la sección
    if (question['supportsMultiplePhotos'] == true) {
      return true;
    }
    
    // Por defecto, requiere foto (comportamiento normal)
    return true;
  }

  // 🔧 MÉTODO: Determinar si una pregunta requiere foto para validación
  bool _requiresPhotoForValidation(Map<String, dynamic> question) {
    // Si tiene requiresPhoto = false, nunca requiere foto
    if (question['requiresPhoto'] == false) {
      return false;
    }
    
    // Si tiene requiresPhotoIfTrue = true, solo requiere foto si la respuesta es SÍ
    if (question['requiresPhotoIfTrue'] == true) {
      return question['answer'] == true;
    }
    
    // Si soporta múltiples fotos, requiere al menos una foto
    if (question['supportsMultiplePhotos'] == true) {
      return true;
    }
    
    // Por defecto, requiere foto (comportamiento normal)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0082C2), Color(0xFF4DA7D4), Color(0xFF99CDE7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con progreso
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _showExitDialog(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${widget.vehicleName} - ${widget.vehiclePlate}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Pregunta ${_currentQuestionIndex + 1} de ${_questions.length + 1}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentQuestionIndex < _questions.length)
                          CircularProgressIndicator(
                            value: (_currentQuestionIndex + 1) / _questions.length,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Barra de progreso
                    LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _questions.length,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenido de la pregunta
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _currentQuestionIndex < _questions.length
                      ? _buildQuestionPage(_currentQuestionIndex)
                      : _buildSummaryPage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final question = _questions[index];
    
    return SingleChildScrollView(
      controller: _scrollController, // 📜 ASIGNAR CONTROLADOR DE SCROLL
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              question['category'],
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Pregunta
          Text(
            question['question'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0082C2),
            ),
          ),
          const SizedBox(height: 20),
          
          // 🏷️ SECCIÓN DE ETIQUETAS INFORMATIVAS
          if (question['tags'] != null && question['tags'].isNotEmpty) ...[
            _buildTagsSection(question['tags']),
            const SizedBox(height: 30),
          ],
          
          // Botones SI/NO: mostrar por defecto *siempre* salvo que la pregunta marque
          // 'showAnswerButtons': false (usado para preguntas solo-texto).
          // Nota: permitir mostrar SÍ/NO incluso si la pregunta soporta múltiples fotos
          if ((question['showAnswerButtons'] ?? true) == true) ...[
            Row(
              children: [
                Expanded(
                  child: _buildAnswerButton(
                    'SÍ',
                    true,
                    question['answer'] == true,
                    () => _setAnswer(index, true),
                    question, // Pasar la pregunta completa para conocer si SÍ es incidencia
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnswerButton(
                    'NO',
                    false,
                    question['answer'] == false,
                    () => _setAnswer(index, false),
                    question, // Pasar la pregunta completa para conocer si SÍ es incidencia
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 30),
          
          // Sección de foto (solo si es requerida)
          if (_shouldShowPhoto(question)) ...[
            _buildPhotoSection(index),
            const SizedBox(height: 30),
          ],
          
          // Campo especial para fecha de ITV
          if (question['requiresItvDate'] == true) ...[
            _buildItvExpirySection(index),
            const SizedBox(height: 30),
          ],
          
          // Campo especial para fecha de extintor
          if (question['question'].toString().toLowerCase().contains('extintor')) ...[
            _buildExtintorExpirySection(index),
            const SizedBox(height: 30),
          ],
          // Campo de texto específico para preguntas que lo requieran
          if (question['requiresTextAnswer'] == true) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Campo detalle que aparece solo si la respuesta es SÍ para preguntas that require text when yes
              if (question['requiresTextIfYes'] == true && question['answer'] == true) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalle (si respondió SÍ)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _textAnswerControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Ej: Chaleco x2, Triángulos, Botiquín adicional',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
                  const Text(
                    'Detalle equipos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _textAnswerControllers[index],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
          // Campo detalle que aparece para preguntas que piden texto solo si la respuesta es SÍ
          if (question['requiresTextIfYes'] == true && question['answer'] == true && question['requiresTextAnswer'] != true) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuales (detalle)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _textAnswerControllers[index],
                    decoration: const InputDecoration(
                      hintText: 'Ej: Chaleco x2, Triángulos, Botiquín',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
          
          // Campo de observaciones
          _buildObservationsField(index),
          
          const SizedBox(height: 40),
          
          // Botón siguiente
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canProceed(index) ? () => _nextQuestion() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canProceed(index) 
                    ? Colors.transparent 
                    : Colors.grey[300],
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _canProceed(index)
                  ? Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0082C2), Color(0xFF4DA7D4)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          index == _questions.length - 1 ? 'Finalizar Revisión' : 'Siguiente Pregunta',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      _requiresPhotoForValidation(question)
                          ? 'Completa la respuesta y añade una foto'
                          : 'Completa la respuesta',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ WIDGET PARA MOSTRAR ETIQUETAS INFORMATIVAS
  Widget _buildTagsSection(List<dynamic> tags) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
              const SizedBox(width: 8),
              Text(
                'Puntos clave a destacar:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tags.map<Widget>((tag) => _buildSingleTag(tag)).toList(),
        ],
      ),
    );
  }

  Widget _buildSingleTag(Map<String, dynamic> tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (tag['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (tag['color'] as Color).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            tag['icon'] as IconData,
            size: 16,
            color: tag['color'] as Color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tag['text'] as String,
              style: TextStyle(
                fontSize: 13,
                color: (tag['color'] as Color),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(String text, bool value, bool isSelected, VoidCallback onTap, Map<String, dynamic> question) {
    // Determinar si esta combinación debería ser roja (incidencia)
    bool shouldBeRed = false;
    
    if (question['isYesAnIncident'] == true && value == true) {
      // Si SÍ es incidencia y este es el botón SÍ, debe ser rojo
      shouldBeRed = true;
    } else if (question['isYesAnIncident'] != true && value == false) {
      // Si NO es incidencia (comportamiento normal) y este es el botón NO, debe ser rojo
      shouldBeRed = true;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: isSelected
              ? (shouldBeRed
                  ? const LinearGradient(colors: [Colors.red, Colors.redAccent])
                  : const LinearGradient(colors: [Colors.green, Colors.lightGreen]))
              : LinearGradient(colors: [Colors.grey[200]!, Colors.grey[300]!]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? (shouldBeRed ? Colors.red : Colors.green)
                : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  // SECCIÓN DE FOTO CON INDICADOR DE OPTIMIZACIÓN
  Widget _buildPhotoSection(int index) {
    final question = _questions[index];
    final isPhotoRequired = _requiresPhotoForValidation(question);
    
    // Si soporta múltiples fotos, usar el widget especializado
    if (question['supportsMultiplePhotos'] == true) {
      return _buildMultiplePhotosSection(index);
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Text(
                isPhotoRequired ? 'Fotografía (Obligatoria)' : 'Fotografía (Opcional)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPhotoRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isOptimizingImage && _currentQuestionIndex == index) ...[
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[300]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue[50],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Optimizando imagen...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (question['photo'] != null) ...[
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(question['photo']),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Error mostrando imagen: $error');
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 40, color: Colors.red),
                              SizedBox(height: 8),
                              Text('Error cargando imagen'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _takePicture(index),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cambiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _removePicture(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: () => _takePicture(index),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para añadir foto',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // SECCIÓN DE MÚLTIPLES FOTOS
  Widget _buildMultiplePhotosSection(int index) {
    final question = _questions[index];
    final photos = (question['photos'] as List<dynamic>?) ?? [];
  // final optimizedPhotos = (question['optimizedPhotosBytes'] as List<dynamic>?) ?? [];
    // Título y descripción dinámicos basados en la pregunta
    final title = question['category'] != null
        ? '${question['category']} - Fotografías'
        : 'Fotografías';
    String description;
    if (question['tags'] != null && (question['tags'] as List).isNotEmpty) {
      final items = (question['tags'] as List)
          .map((t) => (t['text'] as String))
          .take(4)
          .toList();
      description = 'Añade fotos de: ${items.join(', ')}';
    } else {
      description = 'Añade las fotos necesarias';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (question['requiresPhoto'] == true)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Botón para añadir nueva foto
          GestureDetector(
            onTap: () => _addMultiplePhoto(index),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue[300]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue[50],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 24, color: Colors.blue[700]),
                    const SizedBox(height: 4),
                    Text(
                      photos.isEmpty ? 'Añadir foto' : 'Añadir foto (${photos.length})',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mostrar fotos existentes
          if (photos.isNotEmpty) ...[
            Text(
              'Fotos añadidas (${photos.length}):',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Grid de fotos
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: photos.length,
              itemBuilder: (context, photoIndex) {
                final photoPath = photos[photoIndex];
                return _buildPhotoCard(index, photoIndex, photoPath);
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Añade al menos una foto para continuar',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // TARJETA INDIVIDUAL DE FOTO
  Widget _buildPhotoCard(int questionIndex, int photoIndex, String photoPath) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.file(
                File(photoPath),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _viewPhoto(photoPath),
                  icon: const Icon(Icons.visibility, size: 16),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  onPressed: () => _removeMultiplePhoto(questionIndex, photoIndex),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItvExpirySection(int index) {
    final question = _questions[index];
    final selectedDate = question['itvExpiry'] as DateTime?;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(16),
        color: Colors.orange[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.orange[700]),
              const SizedBox(width: 12),
              const Text(
                'Fecha de Vencimiento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () => _selectItvExpiryDate(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: selectedDate != null ? Colors.orange[700] : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? 'Vence el: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'
                          : 'Toca para seleccionar fecha de vencimiento',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDate != null ? Colors.orange[800] : Colors.grey[600],
                        fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.orange[700],
                  ),
                ],
              ),
            ),
          ),
          
          if (selectedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isItvExpired(selectedDate) ? Colors.red[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isItvExpired(selectedDate) ? Colors.red : Colors.green,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isItvExpired(selectedDate) ? Icons.warning : Icons.check_circle,
                    color: _isItvExpired(selectedDate) ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getItvStatusText(selectedDate),
                      style: TextStyle(
                        color: _isItvExpired(selectedDate) ? Colors.red[800] : Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectItvExpiryDate(int index) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _questions[index]['itvExpiry'] ?? DateTime.now().add(const Duration(days: 365)),
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        helpText: 'Seleccionar fecha de vencimiento ITV',
        cancelText: 'Cancelar',
        confirmText: 'Confirmar',
      );

      if (picked != null) {
        setState(() {
          _questions[index]['itvExpiry'] = picked;
        });
        // No mostrar pop-up. Mantener la vista en la misma pregunta.
        _scrollToTop();
      }
    } catch (e) {
      print('❌ Error al seleccionar fecha: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error al abrir selector de fecha'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isItvExpired(DateTime expiryDate) {
    return expiryDate.isBefore(DateTime.now());
  }

  String _getItvStatusText(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < 0) {
      return 'VENCIDA (${difference.abs()} días vencida)';
    } else if (difference <= 30) {
      return 'Próxima a vencer ($difference días restantes)';
    } else {
      return 'En vigor ($difference días restantes)';
    }
  }

  Widget _buildExtintorExpirySection(int index) {
    final question = _questions[index];
    final selectedDate = question['expiryDate'] as DateTime?;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(16),
        color: Colors.red[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.red[700]),
              const SizedBox(width: 12),
              const Text(
                'Fecha de caducidad del extintor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _selectExtintorExpiryDate(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: selectedDate != null ? Colors.red[700] : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? 'Vence el: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'
                          : 'Toca para seleccionar fecha de caducidad',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDate != null ? Colors.red[800] : Colors.grey[600],
                        fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.red[700],
                  ),
                ],
              ),
            ),
          ),
          if (selectedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isExtintorExpired(selectedDate) ? Colors.red[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isExtintorExpired(selectedDate) ? Colors.red : Colors.green,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isExtintorExpired(selectedDate) ? Icons.warning : Icons.check_circle,
                    color: _isExtintorExpired(selectedDate) ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getExtintorStatusText(selectedDate),
                      style: TextStyle(
                        color: _isExtintorExpired(selectedDate) ? Colors.red[800] : Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectExtintorExpiryDate(int index) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _questions[index]['expiryDate'] ?? DateTime.now().add(const Duration(days: 365)),
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        helpText: 'Seleccionar fecha de caducidad del extintor',
        cancelText: 'Cancelar',
        confirmText: 'Confirmar',
      );
      if (picked != null) {
        setState(() {
          _questions[index]['expiryDate'] = picked;
        });
        // No mostrar pop-up. Mantener la vista en la misma pregunta.
        _scrollToTop();
      }
    } catch (e) {
      print('❌ Error al seleccionar fecha: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Error al abrir selector de fecha'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isExtintorExpired(DateTime expiryDate) {
    return expiryDate.isBefore(DateTime.now());
  }

  String _getExtintorStatusText(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    if (difference < 0) {
      return 'VENCIDO (${difference.abs()} días vencido)';
    } else if (difference <= 30) {
      return 'Próximo a vencer ($difference días restantes)';
    } else {
      return 'En vigor ($difference días restantes)';
    }
  }

  Widget _buildObservationsField(int index) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt, color: Colors.blue[700]),
              const SizedBox(width: 12),
              const Text(
                'Observaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: ValueKey('observations_$index'),
            controller: _observationControllers[index],
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Añade cualquier observación relevante...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // MÉTODO MEJORADO PARA TOMAR FOTOS CON OPTIMIZACIÓN INMEDIATA
  Future<void> _takePicture(int index) async {
    try {
      print('📷 Iniciando captura de imagen para pregunta ${index + 1}...');

      setState(() {
        _isOptimizingImage = true;
      });

      final ImagePicker picker = ImagePicker();
      
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (image != null) {
        print('✅ Imagen capturada: ${image.path}');
        
        final file = File(image.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          print('📄 Tamaño: ${fileSize} bytes');
          
          if (fileSize > 0) {
            // OPTIMIZAR INMEDIATAMENTE LA IMAGEN
            print('🔧 Optimizando imagen inmediatamente...');
            final optimizedBytes = await _optimizeImageImmediate(file);
            
            setState(() {
              _questions[index]['photo'] = image.path;
              _questions[index]['optimizedPhotoBytes'] = optimizedBytes;
              _isOptimizingImage = false;
            });
            
            if (mounted) {
              
              // Mantenernos en la misma pregunta: no navegar ni cerrar la pantalla;
              // desplazar el contenido hacia arriba para que el usuario vea el cambio.
              _scrollToTop();
            }
          } else {
            setState(() {
              _isOptimizingImage = false;
            });
            print('❌ Archivo vacío');
            _showErrorMessage('La imagen está vacía. Inténtalo de nuevo.');
          }
        } else {
          setState(() {
            _isOptimizingImage = false;
          });
          print('❌ Archivo no existe');
          _showErrorMessage('No se pudo guardar la imagen. Inténtalo de nuevo.');
        }
      } else {
        setState(() {
          _isOptimizingImage = false;
        });
        print('ℹ️ Usuario canceló la captura');
      }
    } catch (e, stackTrace) {
      setState(() {
        _isOptimizingImage = false;
      });
      print('❌ ERROR al tomar foto: $e');
      print('📋 Stack trace: $stackTrace');
      
      String errorMessage = 'Error al acceder a la cámara. Verifica los permisos en Configuración.';
      _showErrorMessage(errorMessage);
    }
  }

  // MÉTODO PARA AÑADIR MÚLTIPLES FOTOS
  Future<void> _addMultiplePhoto(int index) async {
    try {
      print('📷 Añadiendo foto múltiple para pregunta ${index + 1}...');

      setState(() {
        _isOptimizingImage = true;
      });

      final ImagePicker picker = ImagePicker();
      
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (image != null) {
        print('✅ Imagen capturada: ${image.path}');
        
        final file = File(image.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          print('📄 Tamaño: ${fileSize} bytes');
          
          if (fileSize > 0) {
            // OPTIMIZAR INMEDIATAMENTE LA IMAGEN
            print('🔧 Optimizando imagen inmediatamente...');
            final optimizedBytes = await _optimizeImageImmediate(file);
            
            setState(() {
              // Añadir la foto al array de fotos
              List<dynamic> photos = _questions[index]['photos'] ?? [];
              List<dynamic> optimizedPhotos = _questions[index]['optimizedPhotosBytes'] ?? [];
              
              photos.add(image.path);
              optimizedPhotos.add(optimizedBytes);
              
              _questions[index]['photos'] = photos;
              _questions[index]['optimizedPhotosBytes'] = optimizedPhotos;
              
              _isOptimizingImage = false;
            });
            
            if (mounted) {
             
              // Mantener la vista en la misma pregunta tras añadir la foto
              _scrollToTop();
            }
          } else {
            setState(() {
              _isOptimizingImage = false;
            });
            print('❌ Archivo vacío');
            _showErrorMessage('La imagen está vacía. Inténtalo de nuevo.');
          }
        } else {
          setState(() {
            _isOptimizingImage = false;
          });
          print('❌ Archivo no existe');
          _showErrorMessage('No se pudo guardar la imagen. Inténtalo de nuevo.');
        }
      } else {
        setState(() {
          _isOptimizingImage = false;
        });
        print('ℹ️ Usuario canceló la captura');
      }
    } catch (e, stackTrace) {
      setState(() {
        _isOptimizingImage = false;
      });
      print('❌ ERROR al tomar foto múltiple: $e');
      print('📋 Stack trace: $stackTrace');
      
      String errorMessage = 'Error al acceder a la cámara. Verifica los permisos en Configuración.';
      _showErrorMessage(errorMessage);
    }
  }

  // MÉTODO PARA REMOVER FOTO MÚLTIPLE
  void _removeMultiplePhoto(int questionIndex, int photoIndex) {
    setState(() {
      List<dynamic> photos = _questions[questionIndex]['photos'] ?? [];
      List<dynamic> optimizedPhotos = _questions[questionIndex]['optimizedPhotosBytes'] ?? [];
      
      if (photoIndex < photos.length) {
        photos.removeAt(photoIndex);
      }
      if (photoIndex < optimizedPhotos.length) {
        optimizedPhotos.removeAt(photoIndex);
      }
      
      _questions[questionIndex]['photos'] = photos;
      _questions[questionIndex]['optimizedPhotosBytes'] = optimizedPhotos;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 8),
              Text('Foto eliminada (${(_questions[questionIndex]['photos'] as List).length} fotos restantes)'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // MÉTODO PARA VER FOTO EN PANTALLA COMPLETA
  void _viewPhoto(String photoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Vista de Foto', style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error cargando imagen',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removePicture(int index) {
    setState(() {
      _questions[index]['photo'] = null;
      _questions[index]['optimizedPhotoBytes'] = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text('Foto eliminada'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _canProceed(int index) {
    final question = _questions[index];
    final hasAnswer = question['answer'] != null;
    final hasPhoto = question['photo'] != null;
    final requiresPhoto = _requiresPhotoForValidation(question);
  final requiresText = question['requiresTextAnswer'] == true;
  final requiresTextIfYes = question['requiresTextIfYes'] == true;
  final textAnswer = (question['textAnswer'] as String?) ?? '';
    
    // Si soporta múltiples fotos, verificar que tenga al menos una
    if (question['supportsMultiplePhotos'] == true) {
      final photos = question['photos'] as List<dynamic>?;
      final photosCount = photos?.length ?? 0;
      final requiredCount = (question['requiredPhotosCount'] as int?) ?? 1;
      final hasEnoughPhotos = photosCount >= requiredCount;
      final needsAnswer = question['showAnswerButtons'] == true;

      // Extintor: fecha obligatoria (no requiere respuesta SÍ/NO a menos que lo pida)
      if (question['question'].toString().toLowerCase().contains('extintor')) {
        final hasExpiryDate = question['expiryDate'] != null;
        final answerOk = !needsAnswer || (question['answer'] != null);
        return hasEnoughPhotos && hasExpiryDate && answerOk && !_isOptimizingImage;
      }

      if (question['requiresItvDate'] == true) {
        final hasItvDate = question['itvExpiry'] != null;
        final answerOk = !needsAnswer || (question['answer'] != null);
        return hasEnoughPhotos && hasItvDate && answerOk && !_isOptimizingImage;
      }

      // Para preguntas multi-foto, si se piden botones de respuesta, también exigir respuesta
      if (needsAnswer) {
        return hasEnoughPhotos && question['answer'] != null && !_isOptimizingImage;
      }

      return hasEnoughPhotos && !_isOptimizingImage;
    }
    // Extintor: fecha obligatoria
    if (question['question'].toString().toLowerCase().contains('extintor')) {
      final hasExpiryDate = question['expiryDate'] != null;
      if (requiresPhoto) {
        return hasAnswer && hasPhoto && hasExpiryDate && !_isOptimizingImage;
      } else {
        return hasAnswer && hasExpiryDate && !_isOptimizingImage;
      }
    }
    if (question['requiresItvDate'] == true) {
      final hasItvDate = question['itvExpiry'] != null;
      if (requiresPhoto) {
        return hasAnswer && hasPhoto && hasItvDate && !_isOptimizingImage;
      } else {
        return hasAnswer && hasItvDate && !_isOptimizingImage;
      }
    }
    if (requiresPhoto) {
      // Si además requiere texto, exigir texto no vacío
      if (requiresText) {
  return hasAnswer && hasPhoto && textAnswer.trim().isNotEmpty && !_isOptimizingImage;
      }
      return hasAnswer && hasPhoto && !_isOptimizingImage;
    } else {
      // Si requiere texto sólo cuando la respuesta es SÍ, comprobar condición
      if (requiresTextIfYes) {
        if (question['answer'] == true) {
          return textAnswer.trim().isNotEmpty && !_isOptimizingImage;
        } else {
          return hasAnswer && !_isOptimizingImage;
        }
      }

      if (requiresText) {
        return textAnswer.trim().isNotEmpty && !_isOptimizingImage;
      }
      return hasAnswer && !_isOptimizingImage;
    }
  }

  void _setAnswer(int index, bool answer) {
    final question = _questions[index];
    final previousAnswer = question['answer'];
    
    setState(() {
      _questions[index]['answer'] = answer;
      
      // Si la pregunta requiere foto solo cuando es SÍ, limpiar la foto cuando cambie a NO
      if (question['requiresPhotoIfTrue'] == true) {
        if (answer == false && previousAnswer == true) {
          // Limpiar la foto cuando cambia de SÍ a NO
          _questions[index]['photo'] = null;
          _questions[index]['optimizedPhotoBytes'] = null;
        }
      }
    });
  }

  void _nextQuestion() {
    // Avanzar a la siguiente pregunta y asegurar que el contenido empiece desde arriba
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _currentQuestionIndex = _questions.length;
      });
    }

    // Desplazar la vista al inicio una vez que el frame se haya renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTop();
    });
  }

  // 📜 NUEVO MÉTODO: SCROLL AUTOMÁTICO HACIA ARRIBA
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildSummaryPage() {
    final completedQuestions = _questions.where((q) {
      final hasAnswer = q['answer'] != null;
      final hasPhoto = q['photo'] != null;
      final requiresPhoto = _requiresPhotoForValidation(q);
      final needsAnswer = q['showAnswerButtons'] == true;

      // Si soporta múltiples fotos, considerar completa si tiene al menos una foto
      if (q['supportsMultiplePhotos'] == true) {
        final photos = q['photos'] as List<dynamic>?;
        final hasMultiplePhotos = photos != null && photos.isNotEmpty;

        if (q['requiresItvDate'] == true) {
          final hasItvDate = q['itvExpiry'] != null;
          // Si además necesita respuesta, exigirla
          final answerOk = !needsAnswer || hasAnswer;
          return hasMultiplePhotos && hasItvDate && answerOk;
        }

        // Si necesita respuesta (showAnswerButtons), exigir respuesta además de fotos
        if (needsAnswer) return hasMultiplePhotos && hasAnswer;

        return hasMultiplePhotos;
      }

      if (q['requiresItvDate'] == true) {
        final hasItvDate = q['itvExpiry'] != null;
        if (requiresPhoto) {
          // Si no hay botones de respuesta, basta con la foto; si sí hay botones, exigir respuesta
          return (!needsAnswer ? hasPhoto : (hasAnswer && hasPhoto)) && hasItvDate;
        } else {
          return !needsAnswer ? hasItvDate : (hasAnswer && hasItvDate);
        }
      }

      if (requiresPhoto) {
        // Si la pregunta no muestra botones SI/NO, consideramos correcta solo por aportar la foto
        return needsAnswer ? (hasAnswer && hasPhoto) : hasPhoto;
      } else {
        // No requiere foto: si tiene botones, exigir respuesta; si no, contar como completada
        return needsAnswer ? hasAnswer : true;
      }
    }).length;
    
    // Contar imágenes optimizadas considerando múltiples fotos
    final optimizedImages = _questions.where((q) {
      if (q['supportsMultiplePhotos'] == true) {
        final optimizedPhotos = q['optimizedPhotosBytes'] as List<dynamic>?;
        return optimizedPhotos != null && optimizedPhotos.isNotEmpty;
      }
      return q['optimizedPhotoBytes'] != null;
    }).length;
    
    // Determinar si hay incidencias considerando la nueva lógica
    final hasIssues = _questions.any((q) {
      if (q['isYesAnIncident'] == true) {
        // Si SÍ es incidencia, hay problema cuando la respuesta es true
        return q['answer'] == true;
      } else {
        // Comportamiento normal: hay problema cuando la respuesta es false
        return q['answer'] == false;
      }
    });
    
    // 📜 ASEGURAR QUE LA PÁGINA DE RESUMEN TAMBIÉN SE VEA DESDE ARRIBA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTop();
    });
    
    return SingleChildScrollView(
      controller: _scrollController, // 📜 USAR EL MISMO CONTROLADOR
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          const Text(
            'Resumen de la Revisión',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0082C2),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // ESTADÍSTICAS MEJORADAS CON INFO DE OPTIMIZACIÓN
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Preguntas\nCompletadas',
                  '$completedQuestions/${_questions.length}',
                  completedQuestions == _questions.length ? Colors.green : Colors.orange,
                  Icons.checklist,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Imágenes\nOptimizadas',
                  'Todas',
                  optimizedImages == _questions.length ? Colors.blue : Colors.purple,
                  Icons.image_outlined,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Estado\nGeneral',
                  hasIssues ? 'Con Incidencias' : 'Sin Incidencias',
                  hasIssues ? Colors.red : Colors.green,
                  hasIssues ? Icons.warning : Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Listo para\nEnviar',
                  completedQuestions == _questions.length ? 'SÍ' : 'NO',
                  completedQuestions == _questions.length ? Colors.green : Colors.orange,
                  completedQuestions == _questions.length ? Icons.send : Icons.pending,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Lista de respuestas
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respuestas de la Revisión (${_questions.length} preguntas):',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  return _buildSummaryItem(index + 1, question);
                }).toList(),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Botón enviar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: completedQuestions == _questions.length && !_isGeneratingReport
                  ? _generateAndSendReport
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: completedQuestions == _questions.length && !_isGeneratingReport
                    ? Colors.transparent 
                    : Colors.grey[300],
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isGeneratingReport
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Generando reporte...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : completedQuestions == _questions.length
                      ? Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0082C2), Color(0xFF4DA7D4)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Text(
                              'Enviar Reporte',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'Completa todas las preguntas requeridas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
            ),
          ),
          // Botón Volver a las preguntas SOLO en el resumen
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentQuestionIndex = _questions.length - 1;
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0082C2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Volver a las preguntas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0082C2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Método para determinar el color correcto de la respuesta

  Widget _buildSummaryItem(int number, Map<String, dynamic> question) {
    final hasAnswer = question['answer'] != null;
    final answer = question['answer'];
    final isYesIncident = question['isYesAnIncident'] == true;
    final color = !hasAnswer
      ? Colors.grey
      : (answer == true
          ? (isYesIncident ? Colors.red : Colors.green)
          : (isYesIncident ? Colors.green : Colors.red));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$number.',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question['question'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              if (!hasAnswer)
                const Icon(Icons.help_outline, color: Colors.grey)
              else if (answer == true)
                Icon(Icons.check, color: isYesIncident ? Colors.red : Colors.green)
              else
                Icon(Icons.close, color: isYesIncident ? Colors.green : Colors.red)
            ],
          ),
          // Mostrar fecha de caducidad del extintor debajo de la pregunta del extintor
          if (question['question'].toString().toLowerCase().contains('extintor'))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                question['expiryDate'] != null
                  ? 'Fecha de caducidad del extintor: ' + (question['expiryDate'] is DateTime
                      ? DateFormat('dd/MM/yyyy').format(question['expiryDate'])
                      : question['expiryDate'].toString())
                  : 'Fecha de caducidad del extintor: No indicada',
                style: const TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            ),
          // Observaciones
          if ((question['observations'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Observaciones: ${question['observations']}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

  // MÉTODO MEJORADO PARA GENERAR REPORTE (SIN OPTIMIZACIÓN ADICIONAL)
  Future<void> _generateAndSendReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      print('📄 Iniciando generación de reporte...');
      print('📊 Total preguntas a procesar: ${_questions.length}');
      
      // Sincronizar observaciones
      for (int i = 0; i < _questions.length; i++) {
        _questions[i]['observations'] = _observationControllers[i].text;
        print('🔍 Pregunta ${i + 1}: ${_questions[i]['question'].toString().length > 30 ? _questions[i]['question'].toString().substring(0, 30) + "..." : _questions[i]['question']}');
        print('   Respuesta: ${_questions[i]['answer']}');
        print('   Foto: ${_questions[i]['photo'] != null ? 'SÍ' : 'NO'}');
        print('   Optimizada: ${_questions[i]['optimizedPhotoBytes'] != null ? 'SÍ' : 'NO'}');
        
        if (_questions[i]['requiresItvDate'] == true) {
          final itvDate = _questions[i]['itvExpiry'];
          if (itvDate != null) {
            print('   Fecha ITV: ${DateFormat('dd/MM/yyyy').format(itvDate)}');
          }
        }
      }

      // GENERAR PDF CON IMÁGENES PRE-OPTIMIZADAS
      final pdfService = PDFService();
      final pdfBytes = await pdfService.generateInspectionReportOptimized(
        vehicleName: widget.vehicleName,
        vehiclePlate: widget.vehiclePlate,
        inspectorName: widget.inspectorName,
        inspectorRole: widget.inspectorRole,
        questions: _questions,
        inspectionDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      );

      print('✅ PDF generado correctamente: ${pdfBytes.length} bytes');

      final emailService = EmailService();
      final success = await emailService.sendInspectionReport(
        pdfBytes: pdfBytes,
        vehicleName: widget.vehicleName,
        vehiclePlate: widget.vehiclePlate,
        inspectorName: widget.inspectorName,
        inspectorRole: widget.inspectorRole,
      );

      if (success) {
        print('✅ Email enviado correctamente');
        _showSuccessDialog();
      } else {
        print('❌ Error enviando email');
        _showErrorDialog('Error al enviar el reporte por email');
      }
    } catch (e, stackTrace) {
      print('❌ Error generando reporte: $e');
      print('📋 Stack trace: $stackTrace');
      _showErrorDialog('Error al generar el reporte: $e');
    } finally {
      setState(() {
        _isGeneratingReport = false;
      });
    }
  }

  void _showSuccessDialog() {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('¡Reporte Enviado!'),
          ],
        ),
        content: Text(
          'El reporte de revisión con ${_questions.length} preguntas ha sido generado y enviado por email correctamente.\n\n'
          
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Salir de la revisión?'),
        content: const Text(
          'Se perderá todo el progreso de la revisión actual. ¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}