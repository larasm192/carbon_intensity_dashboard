import 'package:flutter/material.dart';
import 'carbon_api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Color indexColour = Colors.grey;
  String lastUpdated = "--:--";
  CurrentCarbon? current;
  List<CarbonToday>? todayData;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    reloadValues();

    // Auto update every 2 secs for testing!
    timer = Timer.periodic(
      const Duration(seconds: 2),
      (Timer t) => reloadValues(),
    );
  }

  void reloadValues() async {
    final carbon = await fetchCurrentIntensity();
    final data = await fetchTodayIntensities();

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
      // Time extracted from API "from" (only HH:MM)
      lastUpdated = carbon.from.substring(11, 16);
      current = carbon;
      todayData = data;
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
                children: [
                  CurrentIntensity(value: current?.intensity),
                  const Text('gCO₂/kWh', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

            // Intensity Graph
            Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              child: AspectRatio(
                aspectRatio: 1,
                child: todayData == null
                    ? const Center(child: CircularProgressIndicator())
                    : IntensityGraph(todayData: todayData!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<FlSpot> convertToSpots(List<CarbonToday> data) {
  return List.generate(data.length, (i) {
    final point = data[i];
    final y =
        (point.actualIntensity != 0
                ? point.actualIntensity
                : point.forecastIntensity)
            .toDouble();
    return FlSpot(i.toDouble(), y);
  });
}

class CurrentIntensity extends StatelessWidget {
  final int? value;
  const CurrentIntensity({super.key, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const CircularProgressIndicator();
    }
    return Text(
      '$value',
      style: const TextStyle(
        fontSize: 65,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

class IntensityGraph extends StatelessWidget {
  final List<CarbonToday> todayData;
  const IntensityGraph({super.key, required this.todayData});

  Widget bottomTitleWidgets(
    double value,
    TitleMeta meta,
    List<CarbonToday> todayData,
  ) {
    int index = value.toInt();
    String time = todayData[index].to.substring(11, 16);

    return SideTitleWidget(meta: meta, child: Text(time));
  }

  @override
  Widget build(BuildContext context) {
    final spots = convertToSpots(todayData);

    return LineChart(
      LineChartData(
        minY: 0,
        // calculate maxY based on data?
        maxY: 300,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.white,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Time of Day'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return bottomTitleWidgets(value, meta, todayData);
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Carbon Intensity (gCO₂/kWh)'),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 100,
              reservedSize: 42,
            ),
          ),
        ),
      ),
    );
  }
}

// Update value every 30 mins + time updated √
// Update colour according to index √
// Convert CarbonToday to FLSpots somehow √
// Find a way to make x-axis in time format ?
