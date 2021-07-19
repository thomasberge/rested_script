FROM google/dart-runtime
COPY ./lib/rested_script.dart /app/bin/rested_script.dart
COPY ./test/test.dart /app/bin/server.dart
COPY ./test/pages/ /app/bin/pages/
