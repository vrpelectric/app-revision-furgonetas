// lib/screens/user/user_data_screen.dart
import 'package:flutter/material.dart';
import 'package:login_funcional/screens/auth/login.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:login_funcional/screens/inspection_flow_screen.dart';
import '../../widgets/loading_screen.dart';


class UserDataScreen extends StatefulWidget {
  const UserDataScreen({super.key});

  @override
  State<UserDataScreen> createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> {
  String _userName = '';
  String _userStore = '';
  bool _loading = true;
  bool _userNotFound = false;
  String? _selectedVehicle;

  // MATRIZ DE USUARIOS - Aquí defines todos los usuarios autorizados

  // LISTA DE FURGONETAS CON MATRICULAS AUTOMÁTICAS
  final Map<String, String> _vehicleList = {
    'Partner 001': '4702 GGP',
    'Transit 002': '9291 DWS',
    'Transit 003': '4688 FRD',
    'Traffic 004': '1075 HGH',
    'Partner 006': '8705 GGM',
    'Doblo   009': '1175 FKX',
    'Expert  011': '9900 KLZ',
    'Expert  013': '7907 LBV',
    'Doblo   014': '6076 KDL',
    'Traffic 015': '8874 JJH',
    'Kangoo  016': '8985 LGK',
    'Partner 017': '8357 KFH',
    'NV200   018': '3441 KFH',
    'Kangoo  019': '3540 KDV',
    'Berling 021': '8138 KDK',
    'Boxer   022': '9708 GLB',
    'Movano  025': '9857 LXX',
    'Movano  026': '7241 MBG',
    'NV200   027': '7379 LLB',
    'Vivaro  037': '4801 MDM',
    'Combo   038': '3746 MGX',
    'Courier 039': '5270 MJG',
    'DS      040': '5131 MHD',
    'Express 047': '1774 MNH',
    'Express 048': '9562 MSJ',
    'Kangoo  063': '1422 MXH',
    'Kangoo  064': '1832 MXH',
    'Jumper  065': '6450 MZD',
    'Berling 068': '3811 MZZ',
    'Berling 069': '3812 MZZ',
    'Berling 070': '3814 MZZ',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await AuthService().getLoggedEmail();
    if (email != null) {
      final userData = await AuthService().getUser(email);
      if (userData != null) {
        setState(() {
          _userName = userData['name'] ?? '';
          _userStore = userData['store'] ?? '';
          _loading = false;
          _userNotFound = false;
        });
      } else {
        setState(() {
          _loading = false;
          _userNotFound = true;
        });
      }
    } else {
      setState(() {
        _loading = false;
        _userNotFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingScreen();
    }

    if (_userNotFound) {
      return _buildUserNotFoundScreen();
    }

    final currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

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
              // Header compacto
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Logo VRP más pequeño
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'lib/assets/icons/furgorevicon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.local_shipping,
                            color: Color(0xFF0082C2),
                            size: 24,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $_userName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$_userStore • $currentDate',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await AuthService().logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      children: [
                        // Título
                        const Text(
                          'Revisión Periódica Furgonetas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0082C2),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // DROPDOWN PERSONALIZADO INTEGRADO
                        _CustomDropdown(
                          selectedValue: _selectedVehicle,
                          items: _vehicleList,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedVehicle = newValue;
                            });
                          },
                        ),

                        // Información adicional cuando se selecciona una furgoneta
                        if (_selectedVehicle != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green[50]!, Colors.green[100]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[500],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Furgoneta Seleccionada',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      Text(
                                        '$_selectedVehicle - ${_vehicleList[_selectedVehicle]}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Botón para comenzar
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _selectedVehicle != null ? _startInspection : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedVehicle != null
                                  ? Colors.transparent
                                  : Colors.grey[300],
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _selectedVehicle != null
                                ? Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF0082C2),
                                          Color(0xFF4DA7D4)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Comenzar Revisión',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Selecciona una furgoneta primero',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startInspection() {
    if (_selectedVehicle == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionFlowScreen(
          vehicleName: _selectedVehicle!,
          vehiclePlate: _vehicleList[_selectedVehicle!]!,
          inspectorName: _userName,
          inspectorRole: _userStore,
        ),
      ),
    );
  }

  Widget _buildUserNotFoundScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0082C2),
              Color(0xFF4DA7D4),
              Color(0xFF99CDE7),
              Color(0xFFB3D9ED),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Usuario no encontrado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0082C2),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Volver al login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// WIDGET PERSONALIZADO DEL DROPDOWN
class _CustomDropdown extends StatefulWidget {
  final String? selectedValue;
  final Map<String, String> items;
  final Function(String?) onChanged;

  const _CustomDropdown({
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<_CustomDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    setState(() {
      _isOpen = true;
    });

    _animationController.forward();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 8,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.blue.withOpacity(0.3),
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _expandAnimation.value,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: _expandAnimation.value,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        shrinkWrap: true,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final entry = widget.items.entries.elementAt(index);
                          final isSelected = widget.selectedValue == entry.key;

                          return GestureDetector(
                            onTap: () => _selectItem(entry.key),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          Colors.blue[100]!,
                                          Colors.blue[200]!
                                        ],
                                      )
                                    : null,
                                color: isSelected ? null : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue[400]!
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icono de la furgoneta
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isSelected
                                            ? [
                                                Colors.blue[500]!,
                                                Colors.blue[700]!
                                              ]
                                            : [
                                                Colors.grey[400]!,
                                                Colors.grey[600]!
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.local_shipping_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Información de la furgoneta
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isSelected
                                                ? Colors.blue[800]
                                                : Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.credit_card,
                                              size: 12,
                                              color: isSelected
                                                  ? Colors.blue[600]
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Matrícula: ${entry.value}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected
                                                    ? Colors.blue[600]
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Icono de selección
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[500],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    setState(() {
      _isOpen = false;
    });

    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _selectItem(String value) {
    widget.onChanged(value);
    _closeDropdown();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.local_shipping, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Selecciona la furgoneta:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // DROPDOWN CONTAINER PRINCIPAL
        GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isOpen ? Colors.blue[600]! : Colors.blue[300]!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(_isOpen ? 0.3 : 0.1),
                  blurRadius: _isOpen ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono de la furgoneta
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Texto seleccionado
                Expanded(
                  child: widget.selectedValue != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedValue!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Matrícula: ${widget.items[widget.selectedValue!]}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Selecciona una furgoneta...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),

                // Flecha animada
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}