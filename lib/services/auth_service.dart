import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static Database? _db;
  static const String _tableName = 'users';
  static const String _passwordHash = 'f143e67d4d11614ceea46f6f4b52060dc6c59da893ff8cd646a1da37f4308c7a'; // SHA-256 de 'Electric:23'

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_users.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE $_tableName (
            email TEXT PRIMARY KEY,
            name TEXT,
            store TEXT
          )
        ''');
        await _insertInitialUsers(db);
      },
    );
  }

  Future<void> _insertInitialUsers(Database db) async {
    final users = _getInitialUsers();
    for (var user in users) {
      await db.insert(_tableName, user);
    }
  }

  Future<Map<String, String>?> getUser(String email) async {
    final db = await database;
    final result = await db.query(_tableName, where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) {
      return {
        'name': result.first['name'] as String,
        'store': result.first['store'] as String,
      };
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    var user = await getUser(email);
    if (user == null) {
      // Buscar en la lista de usuarios autorizados
      final initialUsers = _getInitialUsers();
      final found = initialUsers.firstWhere(
        (u) => u['email'] == email,
        orElse: () => {},
      );
      if (found.isNotEmpty) {
        // Insertar el usuario en la base de datos
        final db = await database;
        await db.insert(_tableName, found);
        user = found;
      } else {
        return false;
      }
    }
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    if (passwordHash == _passwordHash) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_email', email);
      return true;
    }
    return false;
  }

  List<Map<String, String>> _getInitialUsers() {
    return [
      {'email': 'google@test.com', 'name': 'Google Test', 'store': 'Google Tester'},
      {'email': 'cmeseguer@vrpelectric.com', 'name': 'Cesar Meseguer', 'store': 'Operario VRP Electric'},
      {'email': 'jboix@vrpelectric.com', 'name': 'Juan Boix', 'store': 'Operario VRP Electric'},
      {'email': 'rdasi@vrpelectric.com', 'name': 'Ricardo Dasi', 'store': 'Operario VRP Electric'},
      {'email': 'rcaso@vrpelectric.com', 'name': 'Ricardo Caso', 'store': 'Operario VRP Electric'},
      {'email': 'pmont@vrpelectric.com', 'name': 'Pedro Mont', 'store': 'Operario VRP Electric'},
      {'email': 'amarques@vrpelectric.com', 'name': 'Alvaro Marques', 'store': 'Operario VRP Electric'},
      {'email': 'bmartinezn@vrpelectric.com', 'name': 'Bernardo Martinez', 'store': 'Operario VRP Electric'},
      {'email': 'egonzalez@vrpelectric.com', 'name': 'Enric Gonzalez', 'store': 'Operario VRP Electric'},
      {'email': 'oestela@vrpelectric.com', 'name': 'Oswald Estela', 'store': 'Operario VRP Electric'},
      {'email': 'darias@vrpelectric.com', 'name': 'David Arias', 'store': 'Operario VRP Electric'},
      {'email': 'jsalom@vrpelectric.com', 'name': 'Javier Salom', 'store': 'Operario VRP Electric'},
      {'email': 'npascual@vrpelectric.com', 'name': 'Noel Pascual', 'store': 'Operario VRP Electric'},
      {'email': 'sperpinya@vrpelectric.com', 'name': 'Sebastian Perpiña', 'store': 'Operario VRP Electric'},
      {'email': 'agallego@vrpelectric.com', 'name': 'Antonio Gallego', 'store': 'Operario VRP Electric'},
      {'email': 'jribes@vrpelectric.com', 'name': 'Josep Ribes', 'store': 'Operario VRP Electric'},
      {'email': 'yayala@vrpelectric.com', 'name': 'Yerko Ayala', 'store': 'Operario VRP Electric'},
      {'email': 'jestruch@vrpelectric.com', 'name': 'Jorge Estruch', 'store': 'Operario VRP Electric'},
      {'email': 'atorres@vrpelectric.com', 'name': 'Arturo Torres', 'store': 'Operario VRP Electric'},
      {'email': 'dsancho@vrpelectric.com', 'name': 'Daniel Sancho', 'store': 'Operario VRP Electric'},
      {'email': 'cbanuls@vrpelectric.com', 'name': 'Carlos Bañuls', 'store': 'Operario VRP Electric'},
      {'email': 'rlereu@vrpelectric.com', 'name': 'Ruben Lereu', 'store': 'Operario VRP Electric'},
      {'email': 'eclausi@vrpelectric.com', 'name': 'Edgar Clausi', 'store': 'Operario VRP Electric'},
      {'email': 'jmatoses@vrpelectric.com', 'name': 'Juan Matoses', 'store': 'Operario VRP Electric'},
      {'email': 'abermudez@vrpelectric.com', 'name': 'Adrian Bermudez', 'store': 'Operario VRP Electric'},
      {'email': 'ipastor@vrpelectric.com', 'name': 'Ivan Pastor', 'store': 'Operario VRP Electric'},
      {'email': 'asirviente@vrpelectric.com', 'name': 'Adrian Sirvente', 'store': 'Operario VRP Electric'},
      {'email': 'rcrespo@vrpelectric.com', 'name': 'Ruben Crespo', 'store': 'Operario VRP Electric'},
      {'email': 'jbenavent@vrpelectric.com', 'name': 'Josep Benavent', 'store': 'Operario VRP Electric'},
      {'email': 'cpenuela@vrpelectric.com', 'name': 'Carlos Peñuela', 'store': 'Operario VRP Electric'},
      {'email': 'fnavarro@vrpelectric.com', 'name': 'Fidel Navarro', 'store': 'Operario VRP Electric'},
      {'email': 'abellver@vrpelectric.com', 'name': 'Alejandro Bellver', 'store': 'Operario VRP Electric'},
      {'email': 'sreynal@vrpelectric.com', 'name': 'Salva Reynal', 'store': 'Operario VRP Electric'},
      {'email': 'jmsanchez@vrpelectric.com', 'name': 'Jose Manuel Sanchez', 'store': 'Operario VRP Electric'},
      {'email': 'abenavent@vrpelectric.com', 'name': 'Abel Benavent', 'store': 'Operario VRP Electric'},
      {'email': 'amartinez@vrpelectric.com', 'name': 'Andreu Martinez', 'store': 'Operario VRP Electric'},
      {'email': 'aruescas@vrpelectric.com', 'name': 'Alex Ruescas', 'store': 'Operario VRP Electric'},
      {'email': 'ctorrent@vrpelectric.com', 'name': 'Carlos Torrent', 'store': 'Operario VRP Electric'},
      {'email': 'sbonovrp@gmail.com', 'name': 'Sergio Bono', 'store': 'Operario VRP Electric'},
      {'email': 'jnachervrp@gmail.com', 'name': 'Josep Nacher', 'store': 'Operario VRP Electric'},
      {'email': 'valmudevervrp@gmail.com', 'name': 'Vicente Almudever', 'store': 'Operario VRP Electric'},
      {'email': 'yberrissounevrp@gmail.com', 'name': 'Yahya Berrissoune', 'store': 'Operario VRP Electric'},
      {'email': 'pmartinezvrp@gmail.com', 'name': 'Patrick Martinez', 'store': 'Operario VRP Electric'},
      {'email': 'lgausachvrp@gmail.com', 'name': 'Lucas Gausach', 'store': 'Operario VRP Electric'},
      {'email': 'jlereuvrp@gmail.com', 'name': 'Joel Hernandis', 'store': 'Operario VRP Electric'},
      {'email': 'dani.11.madrid@gmail.com', 'name': 'Daniel Rosenov', 'store': 'Operario VRP Electric'},
      {'email': 'rekeneta@hotmail.com', 'name': 'Andres Requena', 'store': 'Operario VRP Electric'},
      {'email': 'pascual.povedaa@gmail.com', 'name': 'Pascual Poveda', 'store': 'Operario VRP Electric'},
      {'email': 'lbernalvrp@gmail.com', 'name': 'Lucas Bernal', 'store': 'Operario VRP Electric'},
      {'email': 'vitaliylukyanchuk1993@gmail.com', 'name': 'Vitaliy Lukyanchuk', 'store': 'Operario VRP Electric'},
      {'email': 'adriangomezsanchis@gmail.com', 'name': 'Adrian Gomez', 'store': 'Operario VRP Electric'},
      {'email': 'carlosgrau1968@hotmail.es', 'name': 'Juan Grau', 'store': 'Operario VRP Electric'},
      {'email': 'yordan.electric@icloud.com', 'name': 'Yordan Velizarov', 'store': 'Operario VRP Electric'},
      {'email': 'alvaro4000@hotmail.com', 'name': 'Alvaro Cockwell', 'store': 'Operario VRP Electric'},
      {'email': 'mroig@vrpelectric.com', 'name': 'Mauricio Roig', 'store': 'Almacen VRP Electric'},
    ];
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_email');
  }

  Future<String?> getLoggedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('logged_email');
  }
}
