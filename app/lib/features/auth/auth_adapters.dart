/// Auth adapters — imported only by the composition root (lib/main.dart).
library;

export 'data/local/secure_session_storage.dart' show SecureSessionStorage;
export 'data/remote/auth_api.dart' show AuthApi;
export 'data/repositories/auth_repository_impl.dart' show AuthRepositoryImpl, UnconfiguredAuthRepository;
