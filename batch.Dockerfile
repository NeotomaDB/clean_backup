FROM postgres:15

# Install necessary packages
RUN apt-get update && apt-get install -y \
    awscli \
    postgresql-client \
    postgresql-15-postgis-3 \
    postgresql-contrib \
    openssh-client \
    curl \
    tar \
    gzip \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /home/app /home/archives /var/log \
    && chown -R postgres:postgres /home/app /home/archives /var/log

# Copy your scripts
COPY ./app/scrubbed_database.sh /home/app/
COPY ./app/connect_database.sh /home/app/
RUN chmod +x /home/app/*.sh

# Create a startup script that handles both PostgreSQL and your job
COPY ./batch_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/batch_entrypoint.sh

# Set environment variables
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=postgres
ENV PGUSER=postgres
ENV PGDATA=/var/lib/postgresql/data

USER postgres

ENTRYPOINT ["/usr/local/bin/batch_entrypoint.sh"]