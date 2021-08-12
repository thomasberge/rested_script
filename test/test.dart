import 'rested_script.dart';

main() async {
  print("Testing RestedScript:");
  
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
    print("print()\t\t\t\t\t[\u001b[31mFailed\u001b[0m]");
  } else {
    print("print()\t\t\t\t\t[\u001b[32mOK\u001b[0m]");
  }

}

Future<bool> test_include() async {
  bool bugs = true;
  RestedScript restedscript = new RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.parse("index.html");
  if(result == "1234567890") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_download() async {
  bool bugs = true;
  RestedScript restedscript = new RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.parse("downloadfile.txt");
  if(result == "1234567890") {
    bugs = false;
  }
  return bugs;
}

Future<bool> test_print() async {
  bool bugs = true;
  RestedScript restedscript = new RestedScript(root: "/app/bin/pages/");
  String result = await restedscript.parse("print.html");
  if(result == "this is a test!") {
    bugs = false;
  }
  return bugs;
}