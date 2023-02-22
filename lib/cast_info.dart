class CastInfo {
  final String id;
  final String author;
  final String title;
  final String voiceURL;
  final String fileExtension;
  String? filePath;
  final DateTime downloadedDate;

  CastInfo({
    required this.id,
    required this.author,
    required this.title,
    required this.voiceURL,
    required this.fileExtension,
    required this.downloadedDate,
  });

  @override
  String toString() {
    return "CastInfo(id = ${this.id}, author = ${this.author}, title = ${this.title}, voiceURL = ${this.voiceURL}, fileExtension = ${this.fileExtension}, filePath = ${this.filePath}, downloadedDate = ${this.downloadedDate})";
  }

  Map<String, dynamic> toMap() {
    return {
      "id": this.id,
      "author": this.author,
      "title": this.title,
      "voiceURL": this.voiceURL,
      "fileExtension": this.fileExtension,
      "filePath": this.filePath,
      "downloadedDate": this.downloadedDate.toString(),
    };
  }
}
