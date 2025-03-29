import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getPlantCareAdvice(String crop, String location) async {
  final url = Uri.parse("http://192.168.1.7:5000/getPlantCare?city=Chennai&plant=Tomato");

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"crop": crop, "location": location}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["response"];
  } else {
    return "Error fetching advice.";
  }
}
