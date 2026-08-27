import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/scam_map_models.dart';

class ScamMapCache {
  Database? _database;
  List<ScamMapReport> _memory = const [];

  bool get _supportsSqlite {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<List<ScamMapReport>> readReports() async {
    if (!_supportsSqlite) {
      return List.unmodifiable(_memory);
    }

    final database = await _openDatabase();
    final rows = await database.query(
      'scam_map_cache',
      orderBy: 'reported_at DESC',
    );

    return rows.map((row) {
      final json = jsonDecode(row['payload']! as String);
      return ScamMapReport.fromMap(Map<String, dynamic>.from(json as Map));
    }).toList();
  }

  Future<void> replaceReports(List<ScamMapReport> reports) async {
    _memory = List.unmodifiable(reports);

    if (!_supportsSqlite) {
      return;
    }

    final database = await _openDatabase();
    await database.transaction((transaction) async {
      await transaction.delete('scam_map_cache');

      final batch = transaction.batch();
      for (final report in reports) {
        batch.insert('scam_map_cache', {
          'id': report.id,
          'reported_at': report.reportedAt.toIso8601String(),
          'payload': jsonEncode(report.toCacheMap()),
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Database> _openDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, 'visit1my_scam_map.db'),
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE scam_map_cache (
            id TEXT PRIMARY KEY,
            reported_at TEXT NOT NULL,
            payload TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }
}
