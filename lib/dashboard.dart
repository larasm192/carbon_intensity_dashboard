import 'package:flutter/material.dart';
import 'carbon_api.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Color indexColour = Colors.grey;
  String lastUpdated = "--:--";

  @override
  void initState() {
    super.initState();
    loadColour();
  }

  void loadColour() async {
    final carbon = await fetchCurrentIntensity();

    Color colour;
    switch (carbon.index) {
      case "low":
        colour = Colors.green;
        break;
      case "moderate":
        colour = Colors.orange;
        break;
      case "high":
        colour = Colors.red;
        break;
      default:
        colour = Colors.grey;
    }

    setState(() {
      indexColour = colour;
      // Time extracted from API "from" field - only HH:MM
      lastUpdated = carbon.from.substring(11, 16);
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: indexColour,
        title: Text(
          'Last updated: $lastUpdated',
          style: const TextStyle(fontSize: 15),
        ),
      ),

      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Current Intensity
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: indexColour,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(150),
                  bottomRight: Radius.circular(150),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
              child: Column(
                children: const [
                  CurrentIntensity(),
                  Text('gCO₂/kWh', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

            // Intensity Graph
            Container(
              padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
              child: const SizedBox(height: 280, child: IntensityGraph()),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentIntensity extends StatefulWidget {
  const CurrentIntensity({super.key});

  @override
  State<CurrentIntensity> createState() => _CurrentIntensityState();
}

class _CurrentIntensityState extends State<CurrentIntensity> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CurrentCarbon>(
      future: fetchCurrentIntensity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final intensity = snapshot.data!;
          return Text(
            '${intensity.intensity}',
            style: const TextStyle(fontSize: 65, fontWeight: FontWeight.bold),
          );
        } else {
          return const Text('No data available');
        }
      },
    );
  }
}

class IntensityGraph extends StatefulWidget {
  const IntensityGraph({super.key});

  @override
  State<IntensityGraph> createState() => _IntensityGraphState();
}

class _IntensityGraphState extends State<IntensityGraph> {
  @override
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    String text = switch (value.toInt()) {
      2 => 'MAR',
      5 => 'JUN',
      8 => 'SEP',
      _ => '',
    };
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 15);
    String text = switch (value.toInt()) {
      1 => '10K',
      3 => '30k',
      5 => '50k',
      _ => '',
    };

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  Widget build(BuildContext context) => LineChart(
    LineChartData(
      minX: 0,
      maxX: 10,
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
    ),
  );
}

// Update value every 30 mins + time updated
// Update colour according to index √
// Convert CarbonToday to FLSpots somehow
// Find a way to make x-axis in time format
