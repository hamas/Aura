import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get tmdbApiKey =>
      dotenv.isInitialized
          ? (dotenv.env['TMDB_API_KEY'] ?? '3b3e414b17e563a0a42546315f54a9e1')
          : '3b3e414b17e563a0a42546315f54a9e1';

  static String get tmdbReadAccessToken =>
      dotenv.isInitialized
          ? (dotenv.env['TMDB_READ_ACCESS_TOKEN'] ??
              'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIzyjNlNDE0YjE3ZTU2M2EwYTQyNTQ2MzE1ZjU0YTllMSIsIm5iZiI6MTc4OTM4NDk4Mi41MTcsInN1YiI6IjZhYTdkOTE2NTA3NDM4NGQwNTUzODdhYiIsInNjb3BlcyI6WyJhcGlfcmVhZCxdLCJ2ZXJzaW9uIjoxfQ.6AYp8QOYZm9SlVEHC-PQMf3gxFve-fJ4O6wQ6ihGh2o')
          : 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIzyjNlNDE0YjE3ZTU2M2EwYTQyNTQ2MzE1ZjU0YTllMSIsIm5iZiI6MTc4OTM4NDk4Mi41MTcsInN1YiI6IjZhYTdkOTE2NTA3NDM4NGQwNTUzODdhYiIsInNjb3BlcyI6WyJhcGlfcmVhZCxdLCJ2ZXJzaW9uIjoxfQ.6AYp8QOYZm9SlVEHC-PQMf3gxFve-fJ4O6wQ6ihGh2o';
}
