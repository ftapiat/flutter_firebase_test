import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as Firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_test/models/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  User? _user;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Center(
          child: Container(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _makeInput(label: 'username', controller: _usernameController),
                _makeInput(label: 'password', controller: _passwordController),
                ElevatedButton(onPressed: _onLogin, child: Text('Login')),
                if (_user != null)
                  Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Text('Bienvenido ${_user!.toJson()}'),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _makeInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15, top: 10),
      child: TextFormField(
        decoration: InputDecoration(label: Text(label)),
        controller: controller,
      ),
    );
  }

  void _onLogin() {
    final String username = _usernameController.value.text.trim();
    final String password = _passwordController.value.text.trim();

    debugPrint('On Login');
    debugPrint('Username "$username"; Password "$password";');

    if (!_isValid(username, password)) {
      debugPrint('ERROR: Faltan datos');
      return;
    }

    _login(username, password);
  }

  bool _isValid(String username, String password) {
    return username.isNotEmpty && password.isNotEmpty;
  }

  Future<void> _login(String username, String password) async {
    debugPrint('Iniciando sesión');

    try {
      final credentials =
          await Firebase.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: username,
        password: password,
      );

      final dynamic user = await _userFromFirebase(credentials.user);

      if (user == null) {
        throw new Exception('Error al cargar usuario');
      }

      setState(() => _user = user);
    } on Firebase.FirebaseAuthException catch (e) {
      debugPrint('Error CODE ${e.code}');
    } on Exception catch (e) {
      debugPrint('Excepción ${e.toString()}');
    }
  }

  Future<User?> _userFromFirebase(Firebase.User? firebaseUser) async {
    if (firebaseUser == null) {
      return Future.value(null);
    }

    final String docPath = 'users/${firebaseUser.uid}';
    final documentReference = FirebaseFirestore.instance.doc(docPath);
    final snapshot = await documentReference.get();

    User user;
    if (snapshot.data() == null) {
      // Guarda en la BD
      user = new User(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.email ?? ''
      );

      await documentReference.set(user.toJson());
    } else {
      // Transforma usuario con los datos de la BD
      user = User.fromJson(snapshot.data()!);
    }

    return user;
  }
}
