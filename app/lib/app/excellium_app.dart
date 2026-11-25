import 'package:material_ui/material_ui.dart';

import '../features/workbook/workbook_screen.dart';
import 'theme.dart';

class ExcelliumApp extends StatelessWidget {
  const ExcelliumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excellium',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const WorkbookScreen(),
    );
  }
}
