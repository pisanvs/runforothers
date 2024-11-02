import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'scanning_view.dart';
import 'runner_sign_up_page.dart';
import 'set_station_page.dart';
import 'standings_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? role;
  int? station;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('user_roles')
            .select('auth_roles(role_name)')
            .eq('user_id', user.id)
            .single();
        setState(() {
          role = response['auth_roles']["role_name"];
        });
        print(role);
      } on PostgrestException catch (err) {
        print(err.message);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Builder(
      // Use Builder to get a new context
      builder: (BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (role?.isEmpty ?? true) const Text("Your user is not authorized for any tasks, please ask Max to fix this."),
            if (role == 'manager' || role == 'billboard' || role == 'dashboard')
              TextButton(
                onPressed: () => goToRoute(context, const StandingsPage()),
                child: const Text("Standings"),
              ),
            if (role == 'manager' || role == 'signup')
              TextButton(
                onPressed: () => goToRoute(context, const RunnerSignUpPage()),
                child: const Text("Sign Runners Up"),
              ),
            if (role == 'manager' || role == 'scanning_station')
              TextButton(
                onPressed: () => goToRoute(context, SetStationView(onStationChanged: (value) {
                  station = value;
                })),
                child: const Text("Set Station"),
              ),
            if (role == 'manager' || role == 'scanning_station')
              TextButton(
                onPressed: () => goToRoute(context, ScanningView(stationID: station ?? 1)),
                child: const Text("Scan"),
              ),
          ],
        );
      },
    );
  }
}
