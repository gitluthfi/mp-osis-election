class Data {
  String? code_voter;
  String? id_voter;
  String? ischosen;
  String? islogin;
  String? nik_voter;
  String? password_voter;
  String? role;

  Data({
    this.code_voter,
    this.id_voter,
    this.ischosen,
    this.islogin,
    this.nik_voter,
    this.password_voter,
    this.role,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      code_voter:     json['code_voter'],
      id_voter:       json['id_voter'],
      ischosen:       json['ischosen'],
      islogin:        json['islogin'],
      nik_voter:      json['nik_voter'],
      password_voter: json['password_voter'],
      role:           json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code_voter':     code_voter,
      'id_voter':       id_voter,
      'ischosen':       ischosen,
      'islogin':        islogin,
      'nik_voter':      nik_voter,
      'password_voter': password_voter,
      'role':           role,
    };
  }
}
