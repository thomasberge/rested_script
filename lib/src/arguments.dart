import 'package:string_tools/string_tools.dart';

class RestedScriptArguments {
  String directoryPath = "";
  List<dynamic> list = [];
  Map<dynamic, dynamic> map = new Map();

  Map args = new Map<String, dynamic>();
  Map setmap = new Map<String, String>();
  Map stringmap = new Map<String, String>();
  Map boolmap = new Map<String, bool>();

  void setDirectoryPath(String path) {
    StringTools cursor = new StringTools(path);
    bool run = cursor.data.contains("/");
    while (run) {
      run = cursor.moveTo("/");
    }
    cursor.deleteAllFromPosition();
    //print("path=" + path);
    //print("directoryPath=" + cursor.data);
  }

  void setBool(String key, bool value) {
    boolmap[key] = value;
  }

  void setString(String key, String value) {
    stringmap[key] = value;
  }

  String getString(String key) {
    if (stringmap.containsKey(key)) {
      return stringmap[key];
    } else {
      print("Key " + key + " does not exist in rscript stringmap.");
      return "";
    }
  }

  bool getBool(String key) {
    if (boolmap.containsKey(key)) {
      return boolmap[key];
    } else {
      print("Key " + key + " does not exist in rscript boolmap.");
      return false;
    }
  }
}
