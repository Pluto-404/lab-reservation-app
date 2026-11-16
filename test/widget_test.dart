import 'package:flutter_test/flutter_test.dart';
import 'package:labbook/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Tema LabBook menampilkan konten', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: Center(child: Text('LabBook'))),
    ));
    expect(find.text('LabBook'), findsOneWidget);
  });
}
