# Install a Apache reverse proxy that provides OIDC authentication against Auth0
FROM debian:stretch-slim

# Install httpd-related packages
RUN apt-get update && apt-get install -y curl && apt-get install -y libjansson4 && apt-get install -y wget && apt-get install -y apache2-bin && apt-get install -y libhiredis0.13 && apt-get install -y apache2
RUN wget https://github.com/zmartzone/mod_auth_openidc/releases/download/v2.3.11/libcjose0_0.6.1.4-1.stretch+1_amd64.deb && dpkg -i libcjose0_0.6.1.4-1.stretch+1_amd64.deb
RUN wget https://github.com/zmartzone/mod_auth_openidc/releases/download/v2.3.11/libapache2-mod-auth-openidc_2.3.11-1.stretch+1_amd64.deb && \
dpkg -i libapache2-mod-auth-openidc_2.3.11-1.stretch+1_amd64.deb

# Don't serve the default web root or port
RUN rm /etc/apache2/sites-enabled/000-default.conf

# Put our reverse proxy config in place
COPY 010-reverseproxy.conf /etc/apache2/sites-enabled/
COPY ports.conf /etc/apache2/ports.conf

# Enable mod_auth_openidc
RUN a2enmod auth_openidc
RUN a2enmod proxy_http

# Start apache in the foreground not as root
RUN chown -R www-data /var/log/apache2
RUN mkdir /var/run/apache2
RUN chown www-data /var/run/apache2
USER www-data
CMD apache2ctl -D FOREGROUND

EXPOSE 8000
