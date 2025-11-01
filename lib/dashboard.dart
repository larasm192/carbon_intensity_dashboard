import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'carbon_api.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Last updated: 19:30',
          style: TextStyle(fontSize: 15),
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
              decoration: const BoxDecoration(
                color: Color.fromRGBO(27, 154, 139, 100),
                borderRadius: BorderRadius.only(
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
              padding: const EdgeInsets.all(12),
              child: const SizedBox(height: 280),
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
    return FutureBuilder<Carbon>(
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
