import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_models.dart';

class ReportService {
  final _supabase = Supabase.instance.client;

  Future<void> submitReport(ScamReport report, {List<File>? evidenceFiles}) async {
    final userId = _supabase.auth.currentUser?.id;
    
    // 1. Upload evidence if any
    List<String> uploadedUrls = [];
    if (evidenceFiles != null && evidenceFiles.isNotEmpty) {
      for (var i = 0; i < evidenceFiles.length; i++) {
        final file = evidenceFiles[i];
        final extension = file.path.split('.').last;
        final path = 'reports/$userId/${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
        
        await _supabase.storage.from('scam-evidence').upload(path, file);
        final url = _supabase.storage.from('scam-evidence').getPublicUrl(path);
        uploadedUrls.add(url);
      }
    }

    // 2. Prepare data
    final data = report.toJson();
    data['reporter_id'] = userId;
    
    // Merge uploaded URLs
    final List<String> finalUrls = [...report.evidenceUrls, ...uploadedUrls];
    data['evidence_urls'] = finalUrls;

    // 3. Insert into database
    await _supabase.from('scam_reports').insert(data);
  }

  Future<List<ScamReport>> getMyReportHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    final response = await _supabase
        .from('scam_reports')
        .select()
        .eq('reporter_id', userId ?? '')
        .order('created_at', ascending: false);

    return (response as List).map((json) => ScamReport(
      id: json['id'],
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: json['location_name'],
      amountLost: (json['amount_lost'] as num?)?.toDouble(),
      evidenceUrls: List<String>.from(json['evidence_urls'] ?? []),
      verificationStatus: json['verification_status'] ?? 'Pending',
      isAnonymous: json['is_anonymous'] ?? false,
      adminNotes: json['admin_notes'],
      createdAt: DateTime.parse(json['created_at']),
    )).toList();
  }
}
