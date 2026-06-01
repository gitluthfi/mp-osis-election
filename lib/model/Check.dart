import 'package:election_flutter_app/model/Data.dart';

class Check {
  List<Data>? data;
  String? message;
  String? status;

  Check({this.data, this.message, this.status});

  factory Check.fromJson(Map<String, dynamic> json) {
    return Check(
      data: json['data'] != null ? (json['data'] as List).map((i) => Data.fromJson(i)).toList() : null,
      message: json['message'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['message'] = this.message;
    map['status'] = this.status;
    if (this.data != null) {
      map['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
