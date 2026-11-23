/// The writes the app can queue. [wire] is the text stored in the outbox table.
enum OutboxKind {
  createTask('create_task', 'Create task'),
  completeTask('complete_task', 'Complete task');

  const OutboxKind(this.wire, this.label);

  final String wire;
  final String label;

  static OutboxKind fromWire(String wire) {
    return values.firstWhere((kind) => kind.wire == wire);
  }
}

enum OutboxState {
  pending('pending'),
  inFlight('in_flight'),
  failed('failed'),
  conflict('conflict');

  const OutboxState(this.wire);

  final String wire;

  static OutboxState fromWire(String wire) {
    return values.firstWhere(
      (state) => state.wire == wire,
      orElse: () => OutboxState.pending,
    );
  }
}
