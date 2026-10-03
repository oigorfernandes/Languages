# Imagem com ffmpeg — o plano Consumption do Azure Functions não traz o binário
# e não permite instalar, então o container é o caminho confiável.
FROM mcr.microsoft.com/azure-functions/python:4-python3.11

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true \
    FFMPEG_BIN=/usr/bin/ffmpeg \
    FFPROBE_BIN=/usr/bin/ffprobe

RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /
RUN pip install --no-cache-dir -r /requirements.txt

COPY . /home/site/wwwroot
