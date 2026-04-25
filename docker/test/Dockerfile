FROM perl:5.42

WORKDIR /app

RUN cpan App::cpanminus

COPY cpanfile Makefile.PL /app/
RUN cpanm --installdeps --with-recommends --with-develop --notest .

COPY . /app

CMD ["sh", "docker/test/entrypoint.sh"]