# This is installing the pgvector extension for postgres
FROM postgis/postgis:16-3.4

ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=neotoma
ENV POSTGRES_CRON_DB=postgres

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    unzip \
    postgresql-server-dev-16 \
    postgresql-16-pglogical \
    postgresql-16-cron \
    && rm -rf /var/lib/apt/lists/*

COPY / /
RUN chmod +x /docker-entrypoint-initdb.d/000_bash.sh

WORKDIR /tmp
RUN git clone https://github.com/pgvector/pgvector.git

WORKDIR /tmp/pgvector
RUN make
RUN make install

STOPSIGNAL SIGINT
