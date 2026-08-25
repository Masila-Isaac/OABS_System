FROM php:8.2-apache

# Install the Postgres extension for PDO
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# serve the project root as the web root index.php ikiwa kama entry point 
COPY . /var/www/html/
WORKDIR /var/www/html

# Render provides the PORT env var at runtime and expects the app to listen on it, so swap Apache's default port 80 for a placeholder now and substitute the real value in when the container actually starts.
RUN sed -i 's/Listen 80/Listen ${PORT}/' /etc/apache2/ports.conf \
    && sed -i 's/:80>/:${PORT}>/' /etc/apache2/sites-available/000-default.conf
ENV PORT=10000
EXPOSE 10000

CMD ["sh", "-c", "sed -i \"s/\\${PORT}/$PORT/g\" /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf && apache2-foreground"]
