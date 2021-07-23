import 'dart:io';
import 'dart:convert';

Future<String> downloadTextFile(String argument) async {
  //console.debug("Downloading " + argument + " ...");
  HttpClient client = new HttpClient();
  HttpClientRequest web_request = await client.getUrl(Uri.parse(argument));
  dynamic result;
  HttpClientResponse web_response = await web_request.close();
  result = await utf8.decoder.bind(web_response).join();
  return result;
}
