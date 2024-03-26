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

WORKDIR /app/report/
RUN flutter build web --release --web-renderer canvaskit

# Stage 2 - Create the run-time image
FROM nginx:alpine
RUN apk add --no-cache python3 py3-pip
COPY --from=build-env /app/report/build/web /usr/share/nginx/html
COPY proxy /app/proxy
COPY default.conf /etc/nginx/conf.d/
WORKDIR /app/proxy
RUN sh -c "pip3 install -r requirements.txt"
CMD ["sh", "-c", "uvicorn server:app --host 0.0.0.0 & nginx -g 'daemon off;'"]
