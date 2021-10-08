import 'rested_script.dart';

main() async {
  if(await test_debug()) {
    print("debug()\t\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("debug()\t\t\t\t\t[\u001b[32mOK\u001b[0m]");  
  } 

  if(await test_wrap_and_content()) {
    print("wrap() / content()\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("wrap() / content()\t\t\t[\u001b[32mOK\u001b[0m]");
  }

  if(await test_include()) {
    print("include()\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("include()\t\t\t\t[\u001b[32mOK\u001b[0m]");
  }

  if(await test_download()) {
    print("download()\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("download()\t\t\t\t[\u001b[32mOK\u001b[0m]");
  }  

  if(await test_print()) {
    print("print() / echo()\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("print() / echo()\t\t\t[\u001b[32mOK\u001b[0m]");
  }

  if(await test_flag()) {
    print("flag()\t\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("flag()\t\t\t\t\t[\u001b[32mOK\u001b[0m]");
  }

  if(await test_printVariable()) {
    print("print(variable)\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("print(variable)\t\t\t\t[\u001b[32mOK\u001b[0m]");  
  }

  if(await test_foreach()) {
    print("{{foreach}}\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("{{foreach}}\t\t\t\t[\u001b[32mOK\u001b[0m]");  
  }

  if(await test_varDeclarations()) {
    print("variable declarations\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("variable declarations\t\t\t[\u001b[32mOK\u001b[0m]");  
  }

  if(await test_comments()) {
    print("comments\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("comments\t\t\t\t[\u001b[32mOK\u001b[0m]");  
  }

  if(await test_sheet()) {
    print("sheet\t\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("sheet\t\t\t\t\t[\u001b[32mOK\u001b[0m]");  
  }
}

Future<bool> test_include() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("index.html");
  if(result == "1234567890") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_download() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("downloadfile.txt");
  if(result == "1234567890") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_print() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("print.html");
  if(result == "this is a test!") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_flag() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("flagsite.html");
  if(result == "404 NOT FOUND") {
    String result = await restedscript.createDocument("flagsite_include.html");
    if(result == "404 NOT FOUND") {
      bugs = false;
    }
  }
  return bugs;
}

Future<bool> test_var() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("variables.html");
  //print(result);
  if(result == "this is a test!") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_wrap_and_content() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("wrapping.html");
  if(result == "ABCDEFGHI") {
    bugs = false;
  } else {
    print(result);
  }
  return bugs;
}

Future<bool> test_printVariable() async {
  bool bugs = true;
  Arguments args = new Arguments();
  args.set("test", "rocketship");
  args.set("condition", true);
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("arguments-stringmap.html", args: args);
  if(result == "This is a rocketship!") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_foreach() async {
  bool bugs = true;
  Arguments args = new Arguments();
  List<String> numbers = [];
  numbers.add("4");
  numbers.add("5");
  numbers.add("6");
  args.set("numbers", numbers);
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("foreach.html", args: args);
  if(result == "123456789") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_debug() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("debug.html");
  if(result == "") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_map() async {
  bool bugs = true;
  Arguments args = new Arguments();
  Map<String, dynamic> testmap = { "name": "Terminator", "version": 2000 };
  args.set("movies", testmap);
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("maps.html", args: args);
  if(result == "This is a rocketship!") {
    bugs = false;
  }
  print(args.getVarTable());
  return bugs;
}

Future<bool> test_varDeclarations() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("varDeclarations.html");
  if(result == "The movie Knives Out has a runtime of 135 minutes") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_comments() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("comments.html");
  if(result == "sneakysolidsnake") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_sheet() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("sheet.html");
  if(result == "?") {
    bugs = false;
  }
  print(result);
  return bugs;
}