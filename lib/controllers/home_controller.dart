import '../data/models/article.dart';
import 'articles_controller.dart';

/// Latest news for the home carousel. Permanent, so returning home does not refetch.
class HomeController extends ArticlesController {
  HomeController(super.repository);

  @override
  Future<Articles> fetch() => repository.latest(skip: 0, limit: 20);
}
