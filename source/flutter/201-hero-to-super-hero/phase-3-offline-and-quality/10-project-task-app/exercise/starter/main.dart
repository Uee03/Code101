// Exercise 10: where does an edit go? Run with: dart run main.dart
//
// The queue holds entries that were not sent yet. When the person edits a task,
// the edit joins an unsent entry about the same task instead of making a new one.

class Entry {
  Entry(this.kind, this.taskId, this.body, {this.sending = false});

  final String kind; // 'create' or 'update'
  final String taskId;
  final Map<String, Object?> body;

  /// true when the request is already on its way: it can no longer change.
  final bool sending;

  @override
  String toString() {
    return '$kind $taskId $body${sending ? ' (sending)' : ''}';
  }
}

final List<Entry> queue = [
  Entry('create', 'a', {
    'title': 'Draft',
    'priority': 'medium',
    'dueDate': '2026-12-01',
  }),
  Entry('update', 'c', {'title': 'Sent'}, sending: true),
];

void queueEdit(String taskId, Map<String, Object?> patch) {
  // TODO 1: find the unsent 'create' entry for taskId. When there is one, add the patch
  //         to its body (addAll: a later value wins, a null stays null) and return.
  // TODO 2: otherwise find an unsent 'update' entry for taskId and merge into it the same way.
  // TODO 3: otherwise (nothing unsent, or the entry is sending) add a new 'update' entry.
  queue.add(Entry('update', taskId, patch));
}

void main() {
  queueEdit('a', {'title': 'Draft v2'});
  queueEdit('a', {'dueDate': null});
  queueEdit('b', {'priority': 'high'});
  queueEdit('b', {'priority': 'low', 'title': 'Renamed'});
  queueEdit('b', {'dueDate': null});
  queueEdit('c', {'priority': 'urgent'});
  queue.forEach(print);
}
