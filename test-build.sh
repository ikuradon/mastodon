#!/bin/bash
set -eu
source /etc/profile.d/nvm.sh
export RAILS_ENV=production

nvm use 12
for cmds in bundle yarn;do if ! type ${cmds} 2>/dev/null 1>/dev/null;then echo "${cmds}: Not found";exit 1;fi;done

cd `dirname $0`

bundle check --path=vendor/bundle || bundle install --path=vendor/bundle --without development test --clean --retry=3 --jobs=5
for pidfile in `ls tmp/pids/sidekiq-*`;do bundle exec sidekiqctl quiet $pidfile;done

bundle check --path=vendor/bundle || bundle install --path=vendor/bundle --without development test --clean --retry=3 --jobs=5
yarn --pure-lockfile && yarn cache clean
bin/rails db:migrate
rsync -ah --delete --exclude=vendor --exclude=node_modules --include=tmp/cache --include=tmp/packs --exclude=tmp ~/code/ builder:~/commcx/
ssh builder ./commcx/build.sh
rsync -ah --delete --exclude=vendor --exclude=node_modules --include=tmp/cache --include=tmp/packs --exclude=tmp builder:~/commcx/ ~/code/

bin/tootctl cache clear
for pidfile in `ls tmp/pids/sidekiq-*`;do bundle exec sidekiqctl stop $pidfile;done

rsync -ah --delete --exclude=vendor --exclude=node_modules --exclude=tmp ~/code/ frontend:~/code/
ssh frontend ./code/update-frontend.sh
