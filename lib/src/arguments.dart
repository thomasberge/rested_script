import 'package:string_tools/string_tools.dart';
import 'sheets.dart';

class Arguments {
  Map<String, String> _varTypes = {};
  Map vars = new Map<String, dynamic>();

  void set(String key, dynamic value) {

    if(value is Map) {
      _varTypes[key] = "Map";
    } else if(value is List) {
      _varTypes[key] = "List";
    } else if(value is bool) {
      _varTypes[key] = "Bool";
    }

    vars[key] = value;
  }

  List<String> getIntKeys() {
    List<String> keys = [];
    for(String k in _varTypes.keys) {
      if(k == "Int") {
        if(_varTypes[k] != null) {
          print("Int variable: " +  _varTypes[k].toString());
        }
      }
    }
    return keys;
  }

  // ----------------- INSTANTIATE VARIABLES ----------------------

  void setSheet(String _key, Sheet _value) {
    if(isVar(_key) == false) {
      _varTypes[_key] = "Sheet";
      vars[_key] = _value;
    } else {
      print("Error: Variable " + _key + " already declared.");
    }
  }

  void setString(String _key, String _value) {
    if(isVar(_key) == false) {
      _varTypes[_key] = "String";
      vars[_key] = _value;
    } else {
      print("Error: Variable " + _key + " already declared.");
    }
  }

  void setInt(String key, int value) {
    if(isVar(key) == false) {
      _varTypes[key] = "Int";
      vars[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  void updateInt(String key, int value) {
    if(isVar(key) == true) {
      _varTypes[key] = "Int";
      vars[key] = value;
    } else {
      print("Error: Integer " + key + " does not exist.");
    }
  }

  void setDouble(String key, int value) {
    if(isVar(key) == false) {
      _varTypes[key] = "Double";
      vars[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }  

  void setBool(String key, bool value) {
    if(isVar(key) == false) {
      _varTypes[key] = "Bool";
      vars[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  void setList(String key, List<dynamic> value) {
    if(isVar(key) == false) {
      _varTypes[key] = "List";
      vars[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  void setMap(String key, Map<String, dynamic> value) {
    if(isVar(key) == false) {
      _varTypes[key] = "Map";
      vars[key] = value;
    } else {
      print("Error: Variable " + key + " already declared.");
    }
  }

  String getAsString(String key) {
    if (vars.containsKey(key)) {
      return vars[key].toString();
    } else {
      print("Key " + key + " does not exist in rscript stringmap.");
      return "%KEYDOESNOTEXIST%";
    }
  }

  dynamic get(String key) {
    if (vars.containsKey(key)) {
      return vars[key];
    } else {
      print("Key " + key + " does not exist in rscript stringmap.");
      return "%KEYDOESNOTEXIST%";
    }
  }

  String getType(String _key) {
    if (_varTypes.containsKey(_key)) {
      return _varTypes[_key].toString();
    } else {
      print("Key " + _key + " does not exist in rscript stringmap.");
      return "%KEYDOESNOTEXIST%";
    }
  }

  String type(String key) {
    return _varTypes[key].toString();
  }

  bool isVar(String key) {
    return _varTypes.containsKey(key);
  }

  bool isNumberVar(String key) {
    if(_varTypes.containsKey(key)) {
      if(_varTypes[key] == "Int" || _varTypes[key] == "Double") {
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
      return double.parse(vars[key]);
    } else {
      print("Error: " + key + " is not of type Double");
      return 0.1;
    }
  }

  String getVarTable() {
    return vars.toString();
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
