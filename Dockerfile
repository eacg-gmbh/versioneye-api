FROM        959013096341.dkr.ecr.eu-central-1.amazonaws.com/versioneye-core:1.0.2
MAINTAINER  Robert Reiz <reiz@versioneye.com>

RUN rm -Rf /app; \
    mkdir /app

ADD . /app

RUN cd /app/ && bundle install;

EXPOSE 9090

CMD /app/start.sh
