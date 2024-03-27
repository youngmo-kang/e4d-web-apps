#Stage 1 - Install dependencies and build the app in a build environment
FROM debian:latest AS build-env
# Install flutter dependencies
RUN apt-get update
RUN apt-get install -y curl git wget build-essential unzip
RUN apt-get clean
# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
# Set flutter path
ENV PATH="${PATH}:/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin"
# Run flutter doctor
RUN flutter doctor -v
RUN flutter channel master
RUN flutter upgrade

COPY report /app/report
RUN rm -rf /app/report/build

WORKDIR /app/report/
RUN flutter build web --release --web-renderer canvaskit

# Stage 2 - Create the run-time image
FROM nginx:alpine
COPY --from=build-env /app/report/build/web /usr/share/nginx/html
