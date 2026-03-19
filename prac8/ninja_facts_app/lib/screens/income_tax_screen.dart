import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

final _getIt = GetIt.instance;

class IncomeTaxScreen extends StatefulWidget {
  const IncomeTaxScreen({super.key});

  @override
  State<IncomeTaxScreen> createState() => _IncomeTaxScreenState();
}

class _IncomeTaxScreenState extends State<IncomeTaxScreen> {
  final _countryController = TextEditingController(text: 'US');
  final _yearController = TextEditingController(text: '2026');
  final _regionsController = TextEditingController(text: 'federal,CA');

  bool _isLoading = false;
  String? _error;
  dynamic _data;

  Future<void> _fetchTax() async {
    final country = _countryController.text.trim().toUpperCase();
    final year = int.tryParse(_yearController.text.trim());
    final regions = _regionsController.text.trim();

    if (country.length != 2 || year == null) {
      setState(() => _error = 'Проверьте country (2 буквы) и year (число).');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _data = null;
    });

    try {
      final dio = _getIt<Dio>();
      final qp = <String, dynamic>{
        'country': country,
        'year': year,
      };
      if (regions.isNotEmpty) qp['regions'] = regions;

      final response = await dio.get('/v2/incometax', queryParameters: qp);

      if (response.statusCode == 200) {
        setState(() => _data = response.data);
      } else {
        setState(() => _error = 'Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Не удалось загрузить: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _pretty(dynamic v) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(v);
    } catch (_) {
      return v?.toString() ?? '—';
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _yearController.dispose();
    _regionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Налоги')),
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
                    'Income Tax (API Ninjas)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _countryController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            hintText: 'US / CA',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            hintText: '2026',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _regionsController,
                    decoration: const InputDecoration(
                      labelText: 'Regions (опционально)',
                      hintText: 'federal,CA',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _fetchTax,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Загрузить'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Подсказка: поддерживаются US и CA. Для US регионы: federal или коды штатов (например CA, NY).',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
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
          if (_data != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ответ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        _pretty(_data),
                        style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_isLoading && _error == null && _data == null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'Заполните параметры и нажмите «Загрузить».',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
        ],
      ),
    );
  }
}

