import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  static const _prefsKey = 'notif_settings';
  bool _auction = true;
  bool _trade = true;
  bool _match = true;
  bool _reminder = true;
  bool _loaded = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _auction = prefs.getBool('${_prefsKey}_auction') ?? true;
      _trade = prefs.getBool('${_prefsKey}_trade') ?? true;
      _match = prefs.getBool('${_prefsKey}_match') ?? true;
      _reminder = prefs.getBool('${_prefsKey}_reminder') ?? true;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefsKey}_$key', value);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Impostazioni notifiche')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Nuova offerta asta'),
            value: _auction,
            onChanged: (v) {
              setState(() => _auction = v);
              _save('auction', v);
            },
          ),
          SwitchListTile(
            title: const Text('Scambio proposto'),
            value: _trade,
            onChanged: (v) {
              setState(() => _trade = v);
              _save('trade', v);
            },
          ),
          SwitchListTile(
            title: const Text('Partita in corso'),
            value: _match,
            onChanged: (v) {
              setState(() => _match = v);
              _save('match', v);
            },
          ),
          SwitchListTile(
            title: const Text('Promemoria formazione'),
            value: _reminder,
            onChanged: (v) {
              setState(() => _reminder = v);
              _save('reminder', v);
            },
          ),
        ],
      ),
    );
  }
}
