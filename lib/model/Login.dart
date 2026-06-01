import 'package:election_flutter_app/model/Data.dart';

class Login {
  List<Data>? data;
  String? message;
  String? status;

  Login({this.data, this.message, this.status});

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
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
