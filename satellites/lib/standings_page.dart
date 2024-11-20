import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StandingsPage extends StatefulWidget {
  const StandingsPage({super.key});

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> standings = [];

  @override
  void initState() {
    super.initState();
    supabase
        .from('runners')
        .stream(primaryKey: ['id'])
        .listen((event) {
          fetchAndProcessData();
        });
  }

  Future<void> fetchAndProcessData() async {
    try {
      final runners = await supabase.from('runners').select();
      final logs = await supabase.from('runner_logs').select();
      final stations = await supabase.from('stations').select();

      final processedData = processRunnerData(runners, logs, stations);
      setState(() {
        standings = processedData;
      });
    } on PostgrestException catch (err) {
      // TODO: Show exception to user
      print(err.message);
    }
  }

  List<Map<String, dynamic>> processRunnerData(List<dynamic> runners, List<dynamic> logs, List<dynamic> stations) {
    Map<int, double> runnerLapCounts = {};
    Map<int, num> stationPositions = {for (var s in stations) s['id']: s['pos']};

    Map<int, num> lastPositions = {};

    for (var log in logs) {
      final runnerId = log['runner_id'] as int;
      final stationId = log['station_id'] as int;
      final stationPosition = stationPositions[stationId] ?? 0.0;

      if (lastPositions.containsKey(runnerId) && stationPosition <= lastPositions[runnerId]!) {
        runnerLapCounts[runnerId] = (runnerLapCounts[runnerId] ?? 0) + 1;
      }

      runnerLapCounts[runnerId] = (runnerLapCounts[runnerId] ?? 0) + stationPosition;
      lastPositions[runnerId] = stationPosition;
    }

    return runners.map((runner) {
      final runnerId = runner['id'] as int;
      return {
        'name': runner['name'],
        'laps': runnerLapCounts[runnerId]?.toString() ?? '0',
      };
    }).toList();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marathon Dashboard'),
      ),
      body: Row(
        children: [
          // Left side: List of standings
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blue[50],
              child: standings.isEmpty
                  ? Center(child: const CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: standings.length,
                      itemBuilder: (context, index) {
                        final runner = standings[index];
                        return ListTile(
                          title: Text(runner['name']),
                          subtitle: Text('Laps: ${runner['laps']}'),
                        );
                      },
                    ),
            ),
          ),
          // Right side: Two blocks for future implementation
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.green[100],
                    child: Center(
                      child: Text('Fastest Lap?'),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.green[200],
                    child: Center(
                      child: Text('Underdog?'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
