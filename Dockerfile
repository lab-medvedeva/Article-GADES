FROM akhtyamovpavel/gades-gpu

LABEL maintainer="akhtyamovpavel@gmail.com"

RUN apt-get update && apt-get install -y python3-pip python3-dev

RUN mkdir -p /srv/
COPY requirements.txt /srv/requirements.txt
COPY install.R /srv/install.R

RUN pip install -r /srv/requirements.txt

RUN Rscript /srv/install.R

COPY . /workspace/Article-GADES

WORKDIR /workspace/Article-GADES
