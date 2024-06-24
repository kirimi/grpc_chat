FROM dart:3.4.3
WORKDIR /app
COPY pubspec.* .
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/main.dart -o server
EXPOSE 4401
ENTRYPOINT [ "/app/server" ]
