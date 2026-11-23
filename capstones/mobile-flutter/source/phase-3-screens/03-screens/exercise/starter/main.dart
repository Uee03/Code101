import 'dart:convert';
void main() {
  final old = <String,Object?>{'title':'Plan','dueDate':'2026-12-01'};
  final edited = <String,Object?>{'title':'Plan','dueDate':null};
  // TODO: encode only fields whose values changed. Keep explicit null.
  print(jsonEncode({'old':old,'edited':edited}));
}
