// Excerpt from Roosevelt Connect (lib/pages/educators/scan_id.dart).
// Lightly trimmed for the showcase; school-specific identifiers replaced. Full source is private.

// Counts prior scans for a purpose to drive the escalating-consequence policy.
  Future<int> _getScanCountForPurpose(int studentId, String purpose) async {
    final firestore = FirebaseFirestore.instance;
    final query = await firestore
        .collection('student_check-in_datalogs')
        .where('student_id', isEqualTo: studentId)
        .where('purpose', isEqualTo: purpose)
        .get();
    return query.docs.length;
  }
