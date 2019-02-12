#!/bin/bash
cd $(dirname $0)
source /etc/profile.d/rvm.sh
export RAILS_ENV=production

bundle install --path=vendor/bundle --without development test --retry=3 --jobs=5
yarn --pure-lockfile && yarn cache clean

passenger-config restart-app --rolling-restart /opt/mastodon/code
pkill -u `id -u` node
