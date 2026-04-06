import 'package:flutter/material.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../screens/medical_intelligence_hub_screen.dart';

/// ==================== MEDICAL INTELLIGENCE QUICK WIDGET ====================
///
/// REUSABLE MEDICAL HUB QUICK ACCESS
/// Can be embedded in home screen, command centers, etc.
///
/// 24-HOUR MARATHON - PHASE 4 (HOURS 15-16)
/// ================================================================

class MedicalIntelligenceQuickWidget extends StatelessWidget {
  final bool showTitle;

  const MedicalIntelligenceQuickWidget({
    Key? key,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MEDICAL INTELLIGENCE',
                style: AkelDesign.subtitle.copyWith(fontSize: 12, letterSpacing: 1.5),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicalIntelligenceHubScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 14, color: AkelDesign.successGreen),
                label: Text(
                  'VIEW ALL',
                  style: AkelDesign.caption.copyWith(
                    color: AkelDesign.successGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AkelDesign.md),
        ],

        Container(
          padding: const EdgeInsets.all(AkelDesign.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AkelDesign.carbonFiber,
                AkelDesign.deepBlack,
              ],
            ),
            borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
            border: Border.all(
              color: AkelDesign.successGreen.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AkelDesign.successGreen.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      ' ',
                      'MEDICAL ID',
                      AkelDesign.successGreen,
                    ),
                  ),
                  const SizedBox(width: AkelDesign.sm),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      ' ',
                      'DR. ANNIE',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AkelDesign.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      ' ',
                      'MEDICATIONS',
                      Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: AkelDesign.sm),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      ' ',
                      'HOSPITALS',
                      AkelDesign.primaryRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String emoji,
      String label,
      Color color,
      ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MedicalIntelligenceHubScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AkelDesign.lg,
            horizontal: AkelDesign.md,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: AkelDesign.xs),
              Text(
                label,
                style: AkelDesign.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}