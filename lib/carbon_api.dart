import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CurrentCarbon {
  final DateTime from;
  final DateTime to;
  final int intensity;
  final String index;

  CurrentCarbon({
    required this.from,
    required this.to,
    required this.intensity,
    required this.index,
  });
}

Future<CurrentCarbon> fetchCurrentIntensity() async {
  final response = await http.get(
    Uri.parse('https://api.carbonintensity.org.uk/intensity'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final data = decoded['data'][0];

    final intensityData = data['intensity'];
    final value = intensityData['actual'] ?? intensityData['forecast'];

    return CurrentCarbon(
      from: DateTime.parse(data['from']).toLocal(),
      to: DateTime.parse(data['to']).toLocal(),
      intensity: value,
      index: intensityData['index'],
    );
  } else {
    throw Exception('Failed to load current intensity');
  }
}

class CarbonToday {
  final DateTime to;
  final int actualIntensity;
  final int forecastIntensity;

  CarbonToday({
    required this.to,
    required this.actualIntensity,
    required this.forecastIntensity,
  });
}

Future<List<CarbonToday>> fetchTodayIntensities() async {
  final response = await http.get(
    Uri.parse('https://api.carbonintensity.org.uk/intensity/date'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    final List data = decoded['data'];

    List<CarbonToday> intensityList = [];
    for (var item in data) {
      final toRaw = item['to'];
      final intensity = item['intensity'] ?? {};
      final actual = intensity['actual'] ?? 0;
      final forecast = intensity['forecast'] ?? 0;

      intensityList.add(
        CarbonToday(
          to: DateTime.parse(toRaw).toLocal(),
          actualIntensity: actual,
          forecastIntensity: forecast,
        ),
      );
    }

    return intensityList;
  } else {
    throw Exception('Failed to load current intensity');
  }
}
