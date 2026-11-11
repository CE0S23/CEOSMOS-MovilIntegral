import 'package:flutter/services.dart';

Future<void> abrirUrl(String url) =>
    const MethodChannel('practica7/abrir_url').invokeMethod<void>('abrir', url);
