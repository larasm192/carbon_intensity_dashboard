import 'package:flutter/material.dart';
import 'carbon_api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

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
      case "very low":
        colour = const Color.fromARGB(255, 14, 104, 89);
        break;
      case "low":
        colour = const Color.fromARGB(255, 27, 154, 139);
        break;
      case "moderate":
        colour = const Color.fromARGB(255, 225, 140, 55);
        break;
      case "high":
        colour = const Color.fromARGB(255, 204, 70, 44);
        break;
      case "very high":
        colour = const Color.fromARGB(255, 136, 36, 59);
        break;
      default:
        colour = Colors.grey;
    }

    setState(() {
      indexColour = colour;
      // Time extracted from API "from" (only HH:MM) after parsing in DateTime
      lastUpdated = carbon.from.toString().substring(11, 16);
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

List<FlSpot> convertActualSpots(List<CarbonToday> data) {
  return List.generate(data.length, (i) {
    final point = data[i];

    if (point.actualIntensity != 0) {
      return FlSpot(i.toDouble(), point.actualIntensity.toDouble());
    }

    return FlSpot.nullSpot;
  });
}

List<FlSpot> convertForecastSpots(List<CarbonToday> data) {
  return List.generate(data.length, (i) {
    final point = data[i];

    if (point.actualIntensity == 0) {
      return FlSpot(i.toDouble(), point.forecastIntensity.toDouble());
    }

    return FlSpot.nullSpot;
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
    String time = todayData[index].to.toString().substring(11, 16);

    return SideTitleWidget(meta: meta, child: Text(time));
  }

  @override
  Widget build(BuildContext context) {
    final spotsActual = convertActualSpots(todayData);
    final spotsForecast = convertForecastSpots(todayData);
    final maxValue = getMaxIntensity(todayData);
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();

                final time = todayData[index].to.toString().substring(11, 16);
                return LineTooltipItem(
                  '$time\n'
                  '${spot.y.toInt()} gCO₂/kWh',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        minY: 0,
        maxY: maxValue + 30,
        lineBarsData: [
          // ACTUAL LINE (solid)
          LineChartBarData(
            spots: spotsActual,
            isCurved: true,
            color: Colors.white,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),

          // FORECAST LINE (dashed)
          LineChartBarData(
            spots: spotsForecast,
            isCurved: true,
            color: Colors.grey,
            barWidth: 3,
            dashArray: [5, 6],
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

double getMaxIntensity(List<CarbonToday> data) {
  int maxValue = 0;

  for (final point in data) {
    final max = point.actualIntensity != 0
        ? point.actualIntensity
        : point.forecastIntensity;
    if (max > maxValue) maxValue = max;
  }
  return maxValue.toDouble();
}
