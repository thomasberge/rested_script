

List<String> supportedVariableTypes = ["Map"];

String isVariableDeclaration(String data) {
  int i = 0;
  String supported = "%NOTSUPPORTED%";
  while(i < supportedVariableTypes.length) {
    if (data.substring(0, supportedVariableTypes[i].length + 1) == supportedVariableTypes[i] + " ")
    {
      supported = supportedVariableTypes[i];
      print(supportedVariableTypes[i] + " is a supported variable type!");
      i = 1000;
    }
    i++;
  }

  if(supported == "%NOTSUPPORTED%") {
    //print(data + " is NOT a supported variable type!");
  }

  return supported;
}
