#!/bin/bash
set -eu

source /etc/profile.d/nvm.sh
nvm use
for cmds in bundle yarn;do if ! type ${cmds} 2>/dev/null 1>/dev/null;then echo "${cmds}: Not found";exit 1;fi;done

cd `dirname $0`

export RAILS_ENV=production

git fetch --all
git merge --no-edit --progress upstream/master

ret=$?
if [ $ret -ne 0 ];then
echo "Merge error"
exit 1
fi

git push -u origin comm.cx

bundle install --path=vendor/bundle --without development test --retry=3 --jobs=5
yarn --pure-lockfile && yarn cache clean

for pidfile in `ls tmp/pids/sidekiq-*`;do bundle exec sidekiqctl quiet $pidfile;done

bin/rails db:migrate
bin/rails assets:precompile
bin/rails comm:revwrite

passenger-config restart-app --rolling-restart .
for pidfile in `ls tmp/pids/sidekiq-*`;do bundle exec sidekiqctl stop $pidfile;done
pkill -u `id -u` node
