import 'dart:io';
import 'dart:convert';

Future<String> downloadTextFile(String argument) async {
  HttpClient client = new HttpClient();
  if(argument.substring(0,1) == '"') {
    if(argument.substring(argument.length - 1, argument.length) == '"') {
      HttpClientRequest web_request = await client.getUrl(Uri.parse(argument.substring(1, argument.length - 1)));
      dynamic result;
      HttpClientResponse web_response = await web_request.close();
      result = await utf8.decoder.bind(web_response).join();
      return result;
    } else {
      print("Error: missing closing quotes in download argument");
      return "";
    }
  } else {
    print("Error: missing starting quotes in download argument");
    return "";
  }
}
