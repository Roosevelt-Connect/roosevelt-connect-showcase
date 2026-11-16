// Excerpt from Roosevelt Connect (lib/pages/educators/scan_id.dart).
// Lightly trimmed for the showcase; school-specific identifiers replaced. Full source is private.

// Looks up the student, computes tardiness from the bell schedule, and writes the check-in log.
  Future<Map<String, dynamic>> _queryUserByEmail(String email) async {
    final firestore = FirebaseFirestore.instance;
    RegExp regExp = RegExp(r'^(\d+)@');
    Match? match = regExp.firstMatch(email);
    int studentIdNumber = 0; 

    if (match != null) {
      String numbers = match.group(1)!; 
      studentIdNumber = int.parse(numbers);
    } else {
      logger.w('No match found for student ID in email: $email');
      return {};
    }

    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    bool tardy = false;
    final DateFormat formatter = DateFormat('EEEE');
    final String weekday = formatter.format(now);
    int hour = now.hour;
    int minute = now.minute;
    int minutes = hour * 60 + minute;

    if (dropdownValue.contains("Attendance Check-In") ||
        dropdownValue.contains("Forgot ID")) {
      if (weekday == "Wednesday") {
        if (minutes > 590) tardy = true; 
      } else {
        if (minutes > 510) tardy = true; 
      }
    } else if (dropdownValue.contains("Off-Campus Check-In")) {
      if (selectedLunch == null) {
        logger.w("Off-Campus Check-In attempted without selecting lunch.");
      } else if (weekday == "Wednesday") {
        if (selectedLunch!.contains("1st lunch") && minutes > 728) tardy = true; 
        if (selectedLunch!.contains("2nd lunch") && minutes > 780) tardy = true; 
      } else if (weekday == "Monday" || weekday == "Tuesday") {
        if (selectedLunch!.contains("1st lunch") && minutes > 739) tardy = true; 
        if (selectedLunch!.contains("2nd lunch") && minutes > 807) tardy = true; 
      } else {
        if (selectedLunch!.contains("1st lunch") && minutes > 754) tardy = true; 
        if (selectedLunch!.contains("2nd lunch") && minutes > 820) tardy = true; 
      }
    } else if (dropdownValue.contains("Office Hours")) {
      if (weekday == "Thursday" || weekday == "Friday") {
        if (minutes > 626) tardy = true; 
      }
    }

    String? teacher = "";
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      teacher = user.email;
    }

    final documentData = {
      'student_id': studentIdNumber,
      'timestamp': formattedDateTime,
      'purpose': dropdownValue,
      'tardy': tardy,
      'approved': false,
      'teacher': teacher,
    };

    try {
      DocumentReference docRef = await firestore.collection('student_check-in_datalogs').add(documentData);
      _latestAddedDocId = docRef.id;
      logger.i('Document added successfully for $email / $studentIdNumber');
    } catch (e) {
      logger.e('Error adding document: $e');
    }

    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        Map<String, dynamic> userDataFromDb =
            userDoc.data() as Map<String, dynamic>;
        return userDataFromDb;
      } else {
        logger.e('No user found with email $email');
        return {};
      }
    } catch (e) {
      logger.e('Error querying user by email: $e');
      return {};
    }
  }
