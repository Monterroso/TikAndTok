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
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing technical implementation...'),
                ],
              ),
            );
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading technical details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement retry functionality
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final analysis = state.analysis;
          if (analysis == null) {
            return const Center(
              child: Text('No technical analysis available yet.'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (analysis.implementationOverview != null) ...[
                Text(
                  'Implementation Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(analysis.implementationOverview!),
                const SizedBox(height: 16),
              ],
              if (analysis.techStack.isNotEmpty) ...[
                Text(
                  'Tech Stack',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: analysis.techStack
                      .map((tech) => Chip(
                            label: Text(tech),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (analysis.architecturePatterns.isNotEmpty) ...[
                Text(
                  'Architecture Patterns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: analysis.architecturePatterns
                      .map((pattern) => Chip(
                            label: Text(pattern),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (analysis.bestPractices.isNotEmpty) ...[
                Text(
                  'Best Practices',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...analysis.bestPractices
                    .map((practice) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(practice)),
                            ],
                          ),
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