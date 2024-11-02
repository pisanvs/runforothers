import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetStationView extends StatefulWidget {
  final ValueChanged<int?> onStationChanged;

  const SetStationView({
    super.key,
    required this.onStationChanged,
  });

  @override
  State<SetStationView> createState() => _SetStationViewState();
}

class _SetStationViewState extends State<SetStationView> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> stations = [];
  List<Map<String, dynamic>> tracks = [];

  int? selectedStation;
  String? selectedTrack;

  final TextEditingController newStationController  = TextEditingController();
  final TextEditingController newTrackController    = TextEditingController();
  final TextEditingController positionController    = TextEditingController();

  late Future<void> tracksFuture;
  late Future<void> stationsFuture;

  @override
  void initState() {
    super.initState();
    tracksFuture = fetchTracks();
    stationsFuture = fetchStations();
  }

  Future<void> fetchStations() async {
    await tracksFuture;
    final track = tracks.firstWhere((track) => track['name'] == selectedTrack,
        orElse: () => {});
    if (track.isNotEmpty) {
      final response =
          await supabase.from('stations').select().eq('track', track['id']);
      setState(() {
        stations = List<Map<String, dynamic>>.from(
            response.map((item) => {'id': item['id'], 'name': item['name']}));
      });
    }
  }

  Future<void> fetchTracks() async {
    final response = await supabase.from('tracks').select('id, name');
    setState(() {
      tracks = List<Map<String, dynamic>>.from(
          response.map((item) => {'id': item['id'], 'name': item['name']}));
    });
  }

  Future<void> addStation() async {
    if (selectedTrack != null) {
      final trackId =
          tracks.firstWhere((track) => track['name'] == selectedTrack)['id'];
      try {
        await supabase.from('stations').insert({
          'name': newStationController.text,
          'track': trackId,
          'pos': double.parse(positionController.text),
        });

        // Guarded by risky op
        newStationController.clear();
        stationsFuture = fetchStations();
      } on PostgrestException catch (err) {
        // TODO: Show exception to user
        print(err.message);
      }
    }
  } // PENDING: 

  Future<void> addTrack() async {
    try {
      await supabase.from('tracks').insert({'name': newTrackController.text});

      // Guarded by risky op
      newTrackController.clear();
      tracksFuture = fetchTracks();
    } on PostgrestException catch (err) {
      // TODO: Show exception to user
      print(err.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Station')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder(
                future: tracksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else {
                    return DropdownButton<String>(
                        hint: const Text("Select Track"),
                        value: selectedTrack,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedTrack = newValue;
                            stationsFuture = fetchStations();
                          });
                        },
                        items: tracks.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> track) {
                          return DropdownMenuItem<String>(
                            value: track['name'],
                            child: Text(track['name']),
                          );
                        }).toList());
                  }
                }),
            FutureBuilder(
                future: stationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else {
                    return DropdownButton<int>(
                      hint: const Text("Select Station"),
                      value: selectedStation,
                      onChanged: (int? newValue) {
                        setState(() {
                          selectedStation = newValue;
                          widget.onStationChanged(newValue);
                        });
                      },
                      items: stations.map<DropdownMenuItem<int>>(
                          (Map<String, dynamic> station) {
                        return DropdownMenuItem<int>(
                          value: station['id'],
                          child: Text(station['name']),
                        );
                      }).toList(),
                    );
                  }
                }),

            TextField(
              controller: newStationController,
              decoration: const InputDecoration(labelText: 'New Station Name'),
            ),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(labelText: 'Position (from 0.0 to 1.0)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\.]')),
              ],
            ), // FEAT: slider
            ElevatedButton(
              onPressed: addStation,
              child: const Text("Add Station"),
            ),
            TextField(
              controller: newTrackController,
              decoration: const InputDecoration(labelText: 'New Track Name'),
            ),
            ElevatedButton(
              onPressed: addTrack,
              child: const Text("Add Track"),
            ),
          ],
        ),
      ),
    );
  }
}
