#!/bin/bash
export RVM_DIR="$HOME/.rvm"
[ -s "$RVM_DIR/scripts/rvm" ] && \. "$RVM_DIR/scripts/rvm"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

cd $(dirname $0)
export RAILS_ENV=production

sed -i '/http_proxy/s/^/#/g' .env.production

bundle install --path=vendor/bundle --without development test --retry=3 --jobs=5
yarn --pure-lockfile && yarn cache clean
bin/rails assets:clobber
time bin/rails assets:precompile
find ./public/assets -name "*.js" -or -name "*.css" | xargs -t brotli -q 10
find ./public/packs -name "*.js" -or -name "*.css" -or -name "*.svg" -or -name "*.ttf" -or -name "*.eot" | xargs -t brotli -q 10
bin/rails comm:revwrite

sed -i '/http_proxy/s/^#//g' .env.production
