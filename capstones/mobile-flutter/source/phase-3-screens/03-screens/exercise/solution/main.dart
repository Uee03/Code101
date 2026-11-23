import 'dart:convert';
void main() {
  final old = <String,Object?>{'title':'Plan','dueDate':'2026-12-01'};
  final edited = <String,Object?>{'title':'Plan','dueDate':null};
  final patch = {for (final entry in edited.entries)
    if (entry.value != old[entry.key]) entry.key:entry.value};
  print(jsonEncode(patch));
}
