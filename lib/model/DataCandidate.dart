class DataCandidate {
  String? idCandidate;
  String? candidateId;
  String? candidateName;
  String? candidatePhoto;
  String? description;

  DataCandidate({
    this.idCandidate,
    this.candidateId,
    this.candidateName,
    this.candidatePhoto,
    this.description,
  });

  factory DataCandidate.fromJson(Map<String, dynamic> json) {
    return DataCandidate(
      idCandidate:    json['id_candidate']?.toString(),
      candidateId:    json['candidate_id']?.toString(),
      candidateName:  json['candidate_name'],
      candidatePhoto: json['candidate_photo'],
      description:    json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_candidate':    idCandidate,
      'candidate_id':    candidateId,
      'candidate_name':  candidateName,
      'candidate_photo': candidatePhoto,
      'description':     description,
    };
  }
}
