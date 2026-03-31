import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document_model.dart';

class FastHubDatabase {
  static const String _dbName = 'fasthub.db';
  static const int _dbVersion = 2; // INCREMENTED DB VERSION

  static Database? _database;
  static final FastHubDatabase instance = FastHubDatabase._init();

  FastHubDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // Added for future schema changes
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { // Migrate from version 1 to 2
      await db.execute('ALTER TABLE documents ADD COLUMN subject TEXT NOT NULL DEFAULT "general"');
      await db.execute('ALTER TABLE documents ADD COLUMN is_offline INTEGER DEFAULT 0');
    }
    // Add migration logic here if schema changes in future versions
    if (oldVersion < 1) { // This block is probably not needed anymore if starting from version 1
      // Example: Create new tables or alter existing ones
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Removed users table creation as it's handled by Supabase profiles and not directly used locally for now.

    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        author_id TEXT NOT NULL,
        filiere TEXT NOT NULL,
        subject TEXT NOT NULL,       -- ADDED subject
        is_public INTEGER DEFAULT 1,
        is_draft INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        pdf_path TEXT,
        preview_html TEXT,
        is_synced INTEGER DEFAULT 0,
        sync_pending INTEGER DEFAULT 0,
        is_offline INTEGER DEFAULT 0 -- Already present from previous change
      )
    ''');


    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        document_id TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, document_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        attempts INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> syncWithSupabase() async {
    final supabase = Supabase.instance.client;
    final db = await database;

    final connectivity = Connectivity();
    final status = await connectivity.checkConnectivity();
    if (status == ConnectivityResult.none) return;

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // 1. Pull documents from Supabase to local DB
        // Fetch only documents relevant to the current user's filiere or authored by them
        final userProfileResponse = await supabase.from('profiles').select('filiere').eq('id', user.id).single();
        final userFiliere = userProfileResponse['filiere'] as String?;

        List<Map<String, dynamic>> supabaseDocuments = [];
        if (userFiliere != null) {
          final publicDocs = await supabase
              .from('documents')
              .select()
              .eq('is_public', true)
              .eq('filiere', userFiliere)
              .order('updated_at', ascending: false);
          supabaseDocuments.addAll(List<Map<String, dynamic>>.from(publicDocs));
        }

        final myDocs = await supabase
            .from('documents')
            .select()
            .eq('author_id', user.id)
            .order('updated_at', ascending: false);
        supabaseDocuments.addAll(List<Map<String, dynamic>>.from(myDocs));

        for (var doc in supabaseDocuments) {
          final mapped = Map<String, dynamic>.from(doc as Map);
          mapped['is_synced'] = 1; // Mark as synced
          mapped['sync_pending'] = 0; // No pending sync
          await db.insert('documents', mapped, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // 2. Push local changes (sync_queue) to Supabase
        final pending = await db.query('sync_queue', where: 'attempts < ?', whereArgs: [5]);
        for (var change in pending) {
          try {
            final operation = change['operation'] as String;
            final table = change['table_name'] as String;
            final recordId = change['record_id'] as String;
            final data = jsonDecode(change['data'] as String) as Map<String, dynamic>;

            if (operation == 'INSERT') {
              await supabase.from(table).insert(data);
              await db.update(
                'documents',
                {'is_synced': 1, 'sync_pending': 0},
                where: 'id = ?',
                whereArgs: [recordId],
              );
            } else if (operation == 'UPDATE') {
              await supabase.from(table).update(data).eq('id', recordId);
              await db.update(
                'documents',
                {'is_synced': 1, 'sync_pending': 0},
                where: 'id = ?',
                whereArgs: [recordId],
              );
            } else if (operation == 'DELETE') {
              await supabase.from(table).delete().eq('id', recordId);
              await db.delete('documents', where: 'id = ?', whereArgs: [recordId]);
            }

            await db.delete('sync_queue', where: 'id = ?', whereArgs: [change['id']]);
          } on PostgrestException catch (e) {
            // Log error, update attempts
            print('Supabase sync error for ${change['operation']} ${change['record_id']}: ${e.message}');
            await db.update('sync_queue', {'attempts': (change['attempts'] as int) + 1}, where: 'id = ?', whereArgs: [change['id']]);
          } catch (e) {
            print('Local sync error for ${change['operation']} ${change['record_id']}: ${e.toString()}');
            await db.update('sync_queue', {'attempts': (change['attempts'] as int) + 1}, where: 'id = ?', whereArgs: [change['id']]);
          }
        }
      }
    } catch (e) {
      print('Overall sync error: ${e.toString()}');
      // Handle overall sync error, e.g., show a notification
    }
  }

  Future<void> _queueSyncOperation(String tableName, String recordId, String operation, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(), // Ensure consistent date format
    });
  }

  Future<void> insertDocument(DocumentModel doc) async {
    final db = await database;
    // Mark as pending sync
    final docToSave = doc.copyWith(isSynced: false, syncPending: true); // isOffline is assumed to be set in doc
    await db.insert('documents', docToSave.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Check if this document already exists in the local DB to decide INSERT or UPDATE for sync_queue
    final existingDoc = await db.query('documents', where: 'id = ?', whereArgs: [doc.id]);
    final operationType = existingDoc.isEmpty ? 'INSERT' : 'UPDATE';
    
    await _queueSyncOperation('documents', doc.id, operationType, docToSave.toJson()); // Use toJson for Supabase format
  }

  Future<void> updateDocumentOffline(DocumentModel doc) async {
    final db = await database;
    final docToUpdate = doc.copyWith(isSynced: false, syncPending: true);
    await db.update('documents', docToUpdate.toMap(), where: 'id = ?', whereArgs: [doc.id]);
    await _queueSyncOperation('documents', doc.id, 'UPDATE', docToUpdate.toJson());
  }

  Future<void> deleteDocumentOffline(String id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
    // For delete, we might only need the ID to tell Supabase to delete it
    await _queueSyncOperation('documents', id, 'DELETE', {'id': id});
  }

  Future<List<DocumentModel>> getOfflineDocuments() async {
    final db = await database;
    final rows = await db.query('documents', orderBy: 'updated_at DESC');
    return rows.map((r) => DocumentModel.fromLocalMap(r)).toList();
  }
}
