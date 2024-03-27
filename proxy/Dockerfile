FROM ubuntu:latest
RUN apt update 
RUN apt install -y python3 python3-pip
COPY server.py requirements.txt /app/

WORKDIR /app/
RUN pip3 install -r requirements.txt
CMD ["sh", "-c", "uvicorn server:app --host 0.0.0.0"]
