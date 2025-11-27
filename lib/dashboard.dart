import 'package:flutter/material.dart';
import 'carbon_api.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

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
  bool internetConnection = true;
  bool apiConnection = true;
  late StreamSubscription<InternetStatus> _connectionSub;

  @override
  void initState() {
    super.initState();
    reloadValues();

    // Checking Wifi connection
    _connectionSub = InternetConnection().onStatusChange.listen((status) {
      setState(() {
        internetConnection = (status == InternetStatus.connected);
      });
    });

    timer = Timer.periodic(
      const Duration(minutes: 30),
      (Timer t) => reloadValues(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _connectionSub.cancel();
    super.dispose();
  }

  void reloadValues() async {
    try {
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
        apiConnection = true;
        indexColour = colour;
        lastUpdated = carbon.to.toString().substring(11, 16);
        current = carbon;
        todayData = data;
      });
    } catch (e) {
      setState(() {
        apiConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: (internetConnection && apiConnection)
            ? indexColour
            : Colors.grey,

        title: Text(
          !internetConnection
              ? 'No internet connection – Last updated $lastUpdated'
              : !apiConnection
              ? 'API unavailable – Last updated $lastUpdated'
              : 'Last updated: $lastUpdated',
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
    final int index = value.toInt();

    final String time = todayData[index].to.toString().substring(11, 16);

    return SideTitleWidget(
      meta: meta,
      child: Text(
        time,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotsActual = convertActualSpots(todayData);
    final spotsForecast = convertForecastSpots(todayData);
    final maxValue = getMaxIntensity(todayData);
    final maxX = (todayData.length - 1).toDouble();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              final items = <LineTooltipItem>[];
              for (final spot in touchedSpots) {
                final index = spot.x.toInt();
                if (index < 0 || index >= todayData.length) continue;

                final time = todayData[index].to.toString().substring(11, 16);
                items.add(
                  LineTooltipItem(
                    '$time\n'
                    '${spot.y.toInt()} gCO₂/kWh',
                    const TextStyle(color: Colors.white),
                  ),
                );
              }
              return items.isEmpty ? <LineTooltipItem?>[] : items;
            },
          ),
        ),
        minY: 0,
        maxY: maxValue + 30,
        maxX: maxX,
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
            dashArray: [5, 3],
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
            axisNameWidget: const Text(
              'Time of Day',
              style: TextStyle(fontSize: 12),
            ),
            axisNameSize: 15,
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
            axisNameWidget: const Text(
              'Carbon Intensity (gCO₂/kWh)',
              style: TextStyle(fontSize: 12),
            ),
            axisNameSize: 15,
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
