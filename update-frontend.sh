#!/bin/bash
cd $(dirname $0)
source /etc/profile.d/rvm.sh
export RAILS_ENV=production

echo "DB_POOL=30" >> .env.production

bundle check --path=vendor/bundle || bundle install --path=vendor/bundle --without development test --clean --retry=3 --jobs=5
yarn --pure-lockfile && yarn cache clean

bin/tootctl cache clear
passenger-config restart-app --rolling-restart /opt/mastodon/code
pkill -u `id -u` node
