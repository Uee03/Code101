package com.code101.tasks.data.local

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

// TODO: a Migration from schema version 1 to 2 that adds the column description (text, never null,
// default empty text) to the table tasks. Use db.execSQL with an ALTER TABLE statement.
val MIGRATION_1_2: Migration = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
    }
}
