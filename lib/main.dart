import 'package:flutter/material.dart';
import 'app.dart';
import 'core/errores_globales.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  instalarManejoGlobalDeErrores();
  runApp(const CeosmosApp());
}
