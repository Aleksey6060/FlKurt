import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

final _getIt = GetIt.instance;

class PlanetsScreen extends StatefulWidget {
  const PlanetsScreen({super.key});

  @override
  State<PlanetsScreen> createState() => _PlanetsScreenState();
}

class _PlanetsScreenState extends State<PlanetsScreen> {
  final _nameController = TextEditingController(text: 'Neptune');
  List<dynamic> _planets = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _fetchPlanets() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _planets = [];
    });

    try {
      final dio = _getIt<Dio>();
      final response = await dio.get(
        '/v1/planets',
        queryParameters: {'name': name},
      );

      if (response.statusCode == 200) {
        setState(() => _planets = response.data as List<dynamic>);
      } else {
        setState(() => _error = 'Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Не удалось загрузить: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _fmtNum(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      return v.toStringAsFixed(v.abs() >= 10 ? 2 : 4).replaceAll(RegExp(r'\.?0+$'), '');
    }
    return '$v';
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Планеты'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Поиск по названию (API Ninjas)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Название планеты',
                      hintText: 'например: Neptune',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _fetchPlanets,
                      ),
                    ),
                    onSubmitted: (_) => _fetchPlanets(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _fetchPlanets,
                    icon: const Icon(Icons.public),
                    label: const Text('Загрузить'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
          if (!_isLoading && _error == null && _planets.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'Введите название и нажмите «Загрузить».',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ..._planets.map((p) {
            final name = (p['name'] ?? '—').toString();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.public, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _row('Mass (Jupiters)', _fmtNum(p['mass'])),
                    _row('Radius (Jupiters)', _fmtNum(p['radius'])),
                    _row('Period (days)', _fmtNum(p['period'])),
                    _row('Semi major axis (AU)', _fmtNum(p['semi_major_axis'])),
                    _row('Temperature (K)', _fmtNum(p['temperature'])),
                    _row('Distance (ly)', _fmtNum(p['distance_light_year'])),
                    _row('Host star mass', _fmtNum(p['host_star_mass'])),
                    _row('Host star temp (K)', _fmtNum(p['host_star_temperature'])),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

