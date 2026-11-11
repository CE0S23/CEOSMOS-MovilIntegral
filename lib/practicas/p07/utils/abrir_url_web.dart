import 'dart:js_interop';

@JS('window.open')
external JSAny? _abrirVentana(JSString url, JSString destino);

Future<void> abrirUrl(String url) async {
  _abrirVentana(url.toJS, '_blank'.toJS);
}
