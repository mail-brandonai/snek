import '../application/run_review.dart';
import '../domain/training_models.dart';
import 'training_services.dart';

class TrainingReviewServices {
  TrainingReviewServices._();

  static Future<RunReviewService> runReviewService() async {
    final services = await TrainingServices.open();
    return RunReviewService(
      runs: services.repositories,
      chunks: services.runChunks,
      lifecycle: services.runLifecycle,
    );
  }
}
