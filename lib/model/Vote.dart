class Vote {
  String? message;
  String? status;

  Vote({this.message, this.status});

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
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
