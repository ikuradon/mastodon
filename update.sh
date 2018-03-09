#!/bin/bash
set -eu
source /etc/profile.d/nvm.sh
export RAILS_ENV=production

nvm use
for cmds in bundle yarn;do if ! type ${cmds} 2>/dev/null 1>/dev/null;then echo "${cmds}: Not found";exit 1;fi;done

cd `dirname $0`

for pidfile in `ls tmp/pids/sidekiq-*`;do bundle exec sidekiqctl quiet $pidfile;done

git fetch --all
git merge --no-commit --progress upstream/master

ret=$?
if [ $ret -ne 0 ];then
echo "Merge error"
git merge --abort
for pidfile in `ls tmp/pids/sidekiq-*`;do bundle exec sidekiqctl stop $pidfile;done
exit 1
fi

git commit -c "Merge remote-tracking branch 'upstream/master' into comm.cx"
git push -u origin comm.cx

bundle install --path=vendor/bundle --without development test --retry=3 --jobs=5
yarn --pure-lockfile && yarn cache clean

bin/rails db:migrate

for pidfile in `ls tmp/pids/sidekiq-*`;do bundle exec sidekiqctl stop $pidfile;done
pkill -u `id -u` node

time bin/rails assets:precompile
bin/rails comm:revwrite

passenger-config restart-app --rolling-restart .
