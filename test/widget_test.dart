import 'package:dgsrehberi/providers/data_provider.dart';
import 'package:dgsrehberi/providers/questions_provider.dart';
import 'package:dgsrehberi/providers/timer_provider.dart';
import 'package:dgsrehberi/screens/home_screen.dart';
import 'package:dgsrehberi/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('compact timer keeps its main action on screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataProvider()),
          ChangeNotifierProvider(create: (_) => QuestionsProvider()),
          ChangeNotifierProvider(create: (_) => TimerProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: HomeScreen(key: UniqueKey()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    final startLabel = find.text('Başlat');
    expect(startLabel, findsOneWidget);
    expect(tester.getRect(startLabel).bottom, lessThan(760));
    expect(find.byType(BannerAdWidget), findsOneWidget);
  });
}
