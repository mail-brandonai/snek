import '../application/run_review.dart';
import '../application/soul_training.dart';
import 'training_services.dart';

class TrainingReviewServices {
  TrainingReviewServices._();

  static Future<SoulTrainingService> soulTrainingService() async {
    final services = await TrainingServices.open();
    return SoulTrainingService(
      runs: services.repositories,
      souls: services.repositories,
    );
  }

  static Future<RunReviewService> runReviewService() async {
    final services = await TrainingServices.open();
    return RunReviewService(
      runs: services.repositories,
      chunks: services.runChunks,
      lifecycle: services.runLifecycle,
    );
  }
}
