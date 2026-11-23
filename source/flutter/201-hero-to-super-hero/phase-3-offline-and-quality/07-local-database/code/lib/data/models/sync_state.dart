/// Where a locally stored item stands compared with the server.
enum SyncState {
  synced,
  pending,
  conflict,
  failed;

  static SyncState fromName(String name) {
    return values.firstWhere(
      (state) => state.name == name,
      orElse: () => SyncState.synced,
    );
  }
}
