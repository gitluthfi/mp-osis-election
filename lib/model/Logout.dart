class Logout {
  String? message;
  String? status;

  Logout({this.message, this.status});

  factory Logout.fromJson(Map<String, dynamic> json) {
    return Logout(
      message: json['message'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['message'] = this.message;
    data['status'] = this.status;
    return data;
  }
}
