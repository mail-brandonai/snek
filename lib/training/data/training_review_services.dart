import 'package:isolate_manager/isolate_manager.dart';

import '../application/run_review.dart';
import '../application/run_review_worker.dart';
import 'training_services.dart';

class TrainingReviewServices {
  TrainingReviewServices._();

  static bool _workerMappingRegistered = false;

  static Future<RunReviewService> runReviewService() async {
    if (!_workerMappingRegistered) {
      IsolateManager.addWorkerMapping(
        analyzeRunReviewChunks,
        'analyzeRunReviewChunks',
      );
      _workerMappingRegistered = true;
    }

    final services = await TrainingServices.open();
    return RunReviewService(
      runs: services.repositories,
      chunks: services.runChunks,
      lifecycle: services.runLifecycle,
    );
  }
}
