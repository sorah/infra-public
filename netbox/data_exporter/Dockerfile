FROM public.ecr.aws/sorah/ruby:3.1
RUN mkdir -p /app /app/tmp

RUN apt-get update && apt-get install -y --no-install-recommends libpq-dev libssl-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY Gemfile* /app/
RUN cd /app && bundle install -j4 --deployment --without 'development test'
COPY . /app/

WORKDIR /app

CMD ["bundle", "exec", "bin/netbox-data-exporter"]
