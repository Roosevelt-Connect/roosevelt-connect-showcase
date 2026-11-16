// Excerpt from Roosevelt Connect (lib/pages/educators/scan_id.dart).
// Lightly trimmed for the showcase; school-specific identifiers replaced. Full source is private.

// Called for every scanned student ID barcode (camera or USB scanner).
  void _foundBarcode(String barcodeCap) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    String? teacher = "";
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      teacher = user.email;
    }

    // Scoped variables so they survive until we build the table row at the end
    int? trackedTotalScans;
    String? trackedConsequence;

    if (dropdownValue == "Event Check-In" ||
        dropdownValue == "Off-Campus Check-Out") {
      try {
        var studentId = int.parse(barcodeCap);

        DocumentSnapshot eventDoc = await firestore
            .collection('event_participants')
            .doc('approved_ids')
            .get();

        if (eventDoc.exists) {
          List<dynamic> approvedIds =
              (eventDoc.data() as Map<String, dynamic>)['ids'] ?? [];
          final bool isApproved = approvedIds.contains(studentId);
          bool tardy = false;

          final documentData = {
            'student_id': studentId,
            'timestamp': formattedDateTime,
            'purpose': dropdownValue,
            'tardy': tardy,
            'approval': isApproved,
            'teacher': teacher,
          };

          DocumentReference docRef = await firestore
              .collection('student_check-in_datalogs')
              .add(documentData);
          _latestAddedDocId = docRef.id;

          if (isApproved) {
            _showDialog("$barcodeCap is approved for $dropdownValue", Colors.green); 
          } else {
            _showDialog("$barcodeCap is denied for $dropdownValue", Colors.red); 
          }
        } else {
          _showDialog("Error: Approved IDs document not found", Colors.red); 
        }
      } catch (e) {
        if (e is FormatException) {
          _showDialog("Invalid barcode format for Student ID: $barcodeCap", Colors.red); 
        } else {
          _showDialog("Error checking approval for $dropdownValue: $e", Colors.red); 
        }
      }
    } else if (dropdownValue == "Off-Campus Check-In") {
      try {
        var studentId = int.parse(barcodeCap);
        bool tardy = false;
        final DateFormat formatter = DateFormat('EEEE');
        final String weekday = formatter.format(now);
        int hour = now.hour;
        int minute = now.minute;
        int minutes = hour * 60 + minute;

        if (selectedLunch == null) {
          _showDialog("Error: Please select a lunch period for Off-Campus Check-In.", Colors.red); 
          return;
        }

        if (weekday == "Wednesday") {
          if (selectedLunch!.contains("1st lunch") && minutes > 728) tardy = true;
          else if (selectedLunch!.contains("2nd lunch") && minutes > 780) tardy = true;
        } else if (weekday == "Monday" || weekday == "Tuesday") {
          if (selectedLunch!.contains("1st lunch") && minutes > 739) tardy = true;
          else if (selectedLunch!.contains("2nd lunch") && minutes > 807) tardy = true;
        } else {
          if (selectedLunch!.contains("1st lunch") && minutes > 754) tardy = true;
          else if (selectedLunch!.contains("2nd lunch") && minutes > 820) tardy = true;
        }

        final documentData = {
          'student_id': studentId,
          'timestamp': formattedDateTime,
          'purpose': dropdownValue,
          'tardy': tardy,
          'approved': false,
          'teacher': teacher,
        };

        DocumentReference docRef = await firestore.collection('student_check-in_datalogs').add(documentData);
        _latestAddedDocId = docRef.id;

        _showDialog(
            "Off-Campus Check-In for $barcodeCap recorded. Tardy: $tardy",
            tardy ? Colors.orangeAccent : Colors.green);
      } catch (e) {
        if (e is FormatException) {
          _showDialog("Invalid barcode format for Student ID: $barcodeCap", Colors.red); 
        } else {
          _showDialog("Error recording Off-Campus Check-In: $e", Colors.red); 
        }
      }
    } else {
      userData = await _queryUserByEmail("$barcodeCap@students.example.edu"); 
      setState(() {
        _scanBarcodeResult = barcodeCap;
      });

      bool isTardy = userData?['tardy'] ?? false;

      if (dropdownValue == "Office Hours Roundup" || dropdownValue == "Forgot ID") {
        int scanCount = await _getScanCountForPurpose(int.parse(barcodeCap), dropdownValue);
        
        int totalScans = scanCount + 1;
        trackedTotalScans = totalScans; // Save to scoped variable

        String consequence;
        if (totalScans == 1) consequence = "Warning";
        else if (totalScans == 2) consequence = "Lunch Detention";
        else if (totalScans == 3) consequence = "Wednesday Detention";
        else if (totalScans == 4) consequence = "No-go & Saturday School";
        else consequence = "Admin & Parent Conference";
        
        trackedConsequence = consequence; // Save to scoped variable

        _showDialog(
            "$dropdownValue for $barcodeCap recorded.\nTotal scans: $totalScans\nConsequence: $consequence",
            isTardy ? Colors.orangeAccent : Colors.green);
      } else {
        if (userData != null && userData!.isNotEmpty) {
          _showDialog(
              "$dropdownValue for $barcodeCap recorded. Tardy: $isTardy",
              isTardy ? Colors.orangeAccent : Colors.green);
        } else if (userData != null) {
          _showDialog("Student ID $barcodeCap $dropdownValue recorded.", Colors.green);
        }
      }
    }

    // After successful scan, add to session table if not already present
    if (mounted && barcodeCap.isNotEmpty) {
        
      bool isTracked = (dropdownValue == "Office Hours Roundup" || dropdownValue == "Forgot ID");

      setState(() {
        _sessionScannedIds.add({
          'docId': _latestAddedDocId,
          'ID': barcodeCap,
          'Purpose': dropdownValue,
          'Timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          // Insert variables cleanly, use a dash "-" if it's not a tracked consequence
          'Total Scans': isTracked && trackedTotalScans != null ? trackedTotalScans.toString() : "-",
          'Consequence': isTracked && trackedConsequence != null ? trackedConsequence : "-",
        });
      });
    }

    if (_isPhysicalScannerModeActive && mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _scanBarcodeResult = null;
            userData = null;
          });
        }
      });
    }
  }
