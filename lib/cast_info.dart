class CastInfo {
  final String id;
  final String author;
  final String title;
  final String voiceURL;
  final String imgURL;
  String? filePath;
  String? imgPath;
  final DateTime downloadedDate;

  CastInfo({
    required this.id,
    required this.author,
    required this.title,
    required this.voiceURL,
    required this.imgURL,
    required this.downloadedDate,
  });

  @override
  String toString() {
    return "CastInfo(id = ${this.id}, author = ${this.author}, title = ${this.title}, voiceURL = ${this.voiceURL}, imgURL: ${this.imgURL}, filePath = ${this.filePath}, imgPath = ${this.imgPath}, downloadedDate = ${this.downloadedDate})";
  }

  Map<String, dynamic> toMap() {
    return {
      "id": this.id,
      "author": this.author,
      "title": this.title,
      "voiceURL": this.voiceURL,
      "imgURL": this.imgURL,
      "filePath": this.filePath,
      "imgPath": this.imgPath,
      "downloadedDate": this.downloadedDate.toString(),
    };
  }
}
