import 'package:string_tools/string_tools.dart';

class Arguments {
  Map<String, String> _varNames = {};
  Map _map = new Map<String, dynamic>();

  void set(String key, dynamic value) {
    if(value is Map) {
      _varNames[key] = "Map";
    }
    _map[key] = value;
  }

  dynamic get(String key) {
    if (_map.containsKey(key)) {
      return _map[key];
    } else {
      print("Key " + key + " does not exist in rscript stringmap.");
      return "%KEYDOESNOTEXIST%";
    }
  }

  String type(String key) {
    return _varNames[key].toString();
  }

  bool isVar(key) {
    return _varNames.containsKey(key);
  }

  String getVarTable() {
    return _map.toString();
  }

  // ------ UNDOCUMENTED OLD STUFF DOWN BELOW THIS LINE ------------- //
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

  bool getBool(String key) {
    if (boolmap.containsKey(key)) {
      return boolmap[key];
    } else {
      print("Key " + key + " does not exist in rscript boolmap.");
      return false;
    }
  }
}
