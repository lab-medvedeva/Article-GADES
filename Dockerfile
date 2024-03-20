FROM akhtyamovpavel/gades-gpu

LABEL maintainer="akhtyamovpavel@gmail.com"

RUN apt-get update && apt-get install -y python3-pip python3-dev

RUN mkdir -p /srv/
COPY requirements.txt /srv/requirements.txt

RUN pip install -r /srv/requirements.txt

COPY . /workspace/Article-GADES

WORKDIR /workspace/Article-GADES
