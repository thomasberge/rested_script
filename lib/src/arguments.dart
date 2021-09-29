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

  List<String> getIntKeys() {
    List<String> keys = [];
    for(String k in _varNames.keys) {
      if(k == "Int") {
        if(_varNames[k] != null) {
          print("Int variable: " +  _varNames[k].toString());
        }
      }
    }
    return keys;
  }

  // ----------------- INSTANTIATE VARIABLES ----------------------

  void setString(String _key, String _value) {
    if(isVar(_key) == false) {
      _varNames[_key] = "String";
      _map[_key] = _value;
    } else {
      print("Error: Variable " + _key + " already declared.");
    }
  }

  void setInt(String key, int value) {
    if(isVar(key) == false) {
      _varNames[key] = "Int";
      _map[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  void updateInt(String key, int value) {
    if(isVar(key) == true) {
      _varNames[key] = "Int";
      _map[key] = value;
    } else {
      print("Error: Integer " + key + " does not exist.");
    }
  }

  void setDouble(String key, int value) {
    if(isVar(key) == false) {
      _varNames[key] = "Double";
      _map[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }  

  void setBool(String key, bool value) {
    if(isVar(key) == false) {
      _varNames[key] = "Bool";
      _map[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  void setList(String key, List<dynamic> value) {
    if(isVar(key) == false) {
      _varNames[key] = "List";
      _map[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  void setMap(String key, Map<String, dynamic> value) {
    if(isVar(key) == false) {
      _varNames[key] = "Map";
      _map[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  String getAsString(String key) {
    if (_map.containsKey(key)) {
      return _map[key].toString();
    } else {
      print("Key " + key + " does not exist in rscript stringmap.");
      return "%KEYDOESNOTEXIST%";
    }
  }

  dynamic get(String key) {
    if (_map.containsKey(key)) {
      return _map[key];
    } else {
      print("Key " + key + " does not exist in rscript stringmap.");
      return "%KEYDOESNOTEXIST%";
    }
  }

  String getType(String _key) {
    if (_varNames.containsKey(_key)) {
      return _varNames[_key].toString();
    } else {
      print("Key " + _key + " does not exist in rscript stringmap.");
      return "%KEYDOESNOTEXIST%";
    }
  }

  String type(String key) {
    return _varNames[key].toString();
  }

  bool isVar(String key) {
    return _varNames.containsKey(key);
  }

  bool isNumberVar(String key) {
    if(_varNames.containsKey(key)) {
      if(_varNames[key] == "Int" || _varNames[key] == "Double") {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  double getDouble(String key) {
    if(isNumberVar(key)) {
      return double.parse(_map[key]);
    } else {
      print("Error: " + key + " is not of type Double");
      return 0.1;
    }
  }

  String getVarTable() {
    return _map.toString();
  }

  void debug() {
    print(getVarTable().toString());
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
}
