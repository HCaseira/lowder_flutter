class EditorMessage {
  final String dataType;
  final dynamic data;

  EditorMessage(this.dataType, this.data);

  EditorMessage.fromJson(Map data)
      : dataType = data["dataType"],
        data = data["data"];

  Map<String, dynamic> toJson() => {
        "dataType": dataType,
        "data": data,
      };
}
