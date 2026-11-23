package com.code101.tasks.data.local

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

val MIGRATION_1_2: Migration = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE IF NOT EXISTS `outbox` (" +
                "`seq` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, " +
                "`id` TEXT NOT NULL, " +
                "`kind` TEXT NOT NULL, " +
                "`entity_id` TEXT NOT NULL, " +
                "`parent_id` TEXT NOT NULL, " +
                "`payload` TEXT NOT NULL, " +
                "`base_version` INTEGER, " +
                "`state` TEXT NOT NULL, " +
                "`attempts` INTEGER NOT NULL, " +
                "`next_attempt_at` INTEGER NOT NULL, " +
                "`problem` TEXT, " +
                "`created_at` INTEGER NOT NULL)",
        )
        db.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS `index_outbox_id` ON `outbox` (`id`)")
        db.execSQL(
            "CREATE INDEX IF NOT EXISTS `index_outbox_state_next_attempt_at` " +
                "ON `outbox` (`state`, `next_attempt_at`)",
        )
    }
}
