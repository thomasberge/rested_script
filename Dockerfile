FROM google/dart-runtime
COPY ./lib/ /app/bin/
COPY ./test/test.dart /app/bin/server.dart
COPY ./test/pages/ /app/bin/pages/
COPY ./test/second/ /app/bin/second/
