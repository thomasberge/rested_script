import 'rested_script.dart';

main() async {
  print("Testing RestedScript:");
  
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

  
  /*
  if(await test_var()) {
    print("var()\t\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("var()\t\t\t\t\t[\u001b[32mOK\u001b[0m]");
  }  
  */
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
  print(result);
  if(result == "this is a test!") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_wrap_and_content() async {
  bool bugs = true;
  RestedScript restedscript = RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.createDocument("wrapping.html");
  print(result);
  return bugs;
}