import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../analytics/plate_calc.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/stepper_pad.dart';

class PlateCalcPage extends StatefulWidget {
  const PlateCalcPage({super.key});
  @override
  State<PlateCalcPage> createState() => _PlateCalcPageState();
}

class _PlateCalcPageState extends State<PlateCalcPage> {
  double target = 60;
  double bar = 20;

  @override
  Widget build(BuildContext context) {
    final load = platesPerSide(target, barKg: bar);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Plate calculator', style: PeakType.overline()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PeakSpacing.edge,
          8,
          PeakSpacing.edge,
          PeakSpacing.edge,
        ),
        children: [
          Text(
            '${target == target.toInt() ? target.toInt() : target.toStringAsFixed(1)} kg',
            style: PeakType.headlineXl().copyWith(fontSize: 44),
          ),
          if (load.achievableKg != target) ...[
            const SizedBox(height: 4),
            Text(
              'Closest achievable with standard plates: ${load.achievableKg} kg',
              style: PeakType.bodyMd(color: PeakColors.tertiary),
            ),
          ],
          const SizedBox(height: 16),
          PeakCard(
            title: 'Target weight',
            child: StepperPad(
              value: target,
              step: 2.5,
              min: bar,
              label: 'kg',
              format: (v) => v == v.toInt() ? '${v.toInt()}' : v.toStringAsFixed(1),
              onChanged: (v) => setState(() => target = v),
            ),
          ),
          const SizedBox(height: 12),
          PeakCard(
            title: 'Bar weight',
            child: StepperPad(
              value: bar,
              step: 5,
              min: 5,
              label: 'kg',
              format: (v) => '${v.toInt()}',
              onChanged: (v) => setState(() => bar = v),
            ),
          ),
          const SizedBox(height: 12),
          PeakCard(
            title: 'Plates per side',
            child: load.plates.isEmpty
                ? Text(
                    'Just the bar.',
                    style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in load.plates)
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: PeakColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${p == p.toInt() ? p.toInt() : p.toStringAsFixed(2)} kg',
                            style: PeakType.buttonLabel(color: PeakColors.primaryForeground),
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
