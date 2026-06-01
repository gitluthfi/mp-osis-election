import 'package:election_flutter_app/model/DataCandidate.dart';

class Candidate {
  String? status;
  String? message;
  List<DataCandidate>? data;

  Candidate({this.status, this.message, this.data});

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      status:  json['status'],
      message: json['message'],
      data:    json['data'] != null
          ? (json['data'] as List).map((e) => DataCandidate.fromJson(e)).toList()
          : null,
    );
  }
}
