import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Carbon {
  final String from;
  final String to;
  final int intensity;
  final String index;

  Carbon({
    required this.from,
    required this.to,
    required this.intensity,
    required this.index,
  });
}

class CarbonToday {
  final List data;

  CarbonToday({required this.data});
}

Future<Carbon> fetchCurrentIntensity() async {
  final response = await http.get(
    Uri.parse('https://api.carbonintensity.org.uk/intensity'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final data = decoded['data'][0];

    final intensityData = data['intensity'];
    final value = intensityData['actual'];

    return Carbon(
      from: data['from'],
      to: data['to'],
      intensity: value,
      index: intensityData['index'],
    );
  } else {
    throw Exception('Failed to load current intensity');
  }
}
