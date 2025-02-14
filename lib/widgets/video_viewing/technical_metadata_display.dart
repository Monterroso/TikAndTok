import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/video_analysis_controller.dart';
import '../../services/gemini_service.dart';

class TechnicalMetadataDisplay extends StatelessWidget {
  final String videoId;

  const TechnicalMetadataDisplay({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VideoAnalysisController(
        context.read<GeminiService>(),
        videoId,
      ),
      child: Consumer<VideoAnalysisController>(
        builder: (context, controller, _) {
          final state = controller.state;
          
          if (state.isLoading) {
            return const CircularProgressIndicator();
          }

          final analysis = state.analysis;
          if (analysis == null) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Technical Implementation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (analysis.implementationOverview != null)
                Text(analysis.implementationOverview!),
              const SizedBox(height: 8),
              Text(
                'Tech Stack',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                children: analysis.techStack
                    .map((tech) => Chip(label: Text(tech)))
                    .toList(),
              ),
              if (analysis.architecturePatterns.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Architecture Patterns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: analysis.architecturePatterns
                      .map((pattern) => Chip(label: Text(pattern)))
                      .toList(),
                ),
              ],
              if (analysis.bestPractices.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Best Practices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...analysis.bestPractices
                    .map((practice) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(practice),
                        ))
                    .toList(),
              ],
            ],
          );
        },
      ),
    );
  }
} 