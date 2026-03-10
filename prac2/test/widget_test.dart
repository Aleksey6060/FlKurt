import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mini_kinopoisk/main.dart';

void main() {
  test('Hive сохраняет и читает Movie', () async {
    final dir = await Directory.systemTemp.createTemp('mini_kinopoisk_test_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MovieAdapter());
    }

    final box = await Hive.openBox<Movie>('movies');
    await box.add(Movie(title: 'Тест', year: 2024, genre: 'Драма'));

    final movie = box.getAt(0);
    expect(movie?.title, 'Тест');
    expect(movie?.year, 2024);
    expect(movie?.genre, 'Драма');

    await box.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });
}
