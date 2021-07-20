FROM wordpress:5.7.2-php7.4

RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
	    libicu-dev \
	; \
	\
	docker-php-ext-configure intl ; \
	docker-php-ext-install \
		intl \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	apt-mark hold libicu-dev ; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug ; \
	docker-php-ext-enable xdebug

RUN { \
        echo "xdebug.mode=debug,profile" ; \
        echo "xdebug.client_host=host.docker.internal" ; \
		echo "xdebug.profiler_enable_trigger=1" ; \
		echo "xdebug.profiler_output_dir=/tmp/xdebug" ; \
		echo "xdebug.start_with_request=trigger" ; \
		echo "xdebug.output_dir=/tmp/xdebug" ; \
	} >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini


