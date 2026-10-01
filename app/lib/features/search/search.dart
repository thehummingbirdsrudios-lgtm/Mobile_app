/// Universal search module public API.
library;

export 'application/search_controller.dart' show searchRepositoryProvider;
export 'domain/search.dart' show SearchHit, SearchKind, SearchRepository, SearchResults, maxSearchQueryLength;
export 'presentation/search_screen.dart' show SearchScreen;
