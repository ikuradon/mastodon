#!/bin/bash
cd $(dirname $0)
source /etc/profile.d/rvm.sh
export RAILS_ENV=production

echo "DB_POOL=30" >> .env.production
echo "CACHE_REDIS_URL=unix:///var/run/redis/redis.sock" >> .env.production

bundle check --path=vendor/bundle || bundle install -j$(getconf _NPROCESSORS_ONLN)
yarn --pure-lockfile && yarn cache clean

bin/tootctl cache clear
passenger-config restart-app --rolling-restart /opt/mastodon/code
pkill -u `id -u` node
