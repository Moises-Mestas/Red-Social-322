import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/services/database_service.dart';

class SearchController {
  final DatabaseService _databaseService = DatabaseService();

  Future<QuerySnapshot> searchUsers(String query) {
    return _databaseService.searchUser(query);
  }

  List<Map<String, dynamic>> filterResults(
    List<Map<String, dynamic>> results,
    String query,
  ) {
    final upperQuery = query.toUpperCase();
    return results.where((element) {
      return element['username'].toString().startsWith(upperQuery);
    }).toList();
  }
}
