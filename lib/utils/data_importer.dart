import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class DataImporter {
  static Future<void> importRouteFares(BuildContext context) async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      
      // 1. Load the JSON from assets
      debugPrint('📦 DataImporter: Loading route_fares.seed.json...');
      final String jsonString = await rootBundle.loadString('firestore/route_fares.seed.json');
      final List<dynamic> data = json.decode(jsonString);
      
      debugPrint('📊 DataImporter: Found ${data.length} records to upload.');
      
      // 2. Upload in batches (Firestore limit is 500 per batch)
      int count = 0;
      WriteBatch batch = db.batch();
      
      for (var item in data) {
        final String docId = item['docId'];
        final Map<String, dynamic> fareData = Map<String, dynamic>.from(item);
        fareData.remove('docId'); // ID is used for the document name
        
        final DocumentReference ref = db.collection('route_fares').doc(docId);
        batch.set(ref, fareData, SetOptions(merge: true));
        
        count++;
        
        // Every 400 records, commit the batch and start a new one
        if (count % 400 == 0) {
          await batch.commit();
          batch = db.batch();
          debugPrint('✅ DataImporter: Uploaded $count records...');
        }
      }
      
      // Commit any remaining records
      if (count % 400 != 0) {
        await batch.commit();
      }
      
      debugPrint('🎉 DataImporter: Successfully uploaded $count records!');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count fares!')),
        );
      }
    } catch (e) {
      debugPrint('❌ DataImporter: Error during import: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import data. Check logs.')),
        );
      }
    }
  }
}
