#!/bin/bash
set -eu
source /etc/profile.d/nvm.sh
export RAILS_ENV=production

nvm use lts/dubnium
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

git merge --abort && git merge --no-edit --progress upstream/master
git push -u origin comm.cx

current_revision=BUNDLE_REV
previous_revision=public/BUNDLE_REV

git rev-parse $(git log --oneline -n 1 Gemfile Gemfile.lock | awk '{{print $1}}') > $current_revision

if [ ! -e $previous_revision ] || ! diff $previous_revision $current_revision; then
    cp -f $current_revision $previous_revision
    bundle install --path=vendor/bundle --without development test --retry=3 --jobs=5
    bundle clean
else
    echo "bundle install skipped"
fi

current_revision=NPM_REV
previous_revision=public/NPM_REV

git rev-parse $(git log --oneline -n 1 package.json yarn.lock | awk '{{print $1}}') > $current_revision

if [ ! -e $previous_revision ] || ! diff $previous_revision $current_revision; then
    cp -f $current_revision $previous_revision
    yarn --pure-lockfile && yarn cache clean
else
    echo "yarn install skipped"
fi

bin/rails db:migrate

for pidfile in `ls tmp/pids/sidekiq-*`;do bundle exec sidekiqctl stop $pidfile;done
pkill -u `id -u` node


current_revision=ASSETS_REV
previous_revision=public/ASSETS_REV

git rev-parse $(git log --oneline -n 1 lib/assets Gemfile.lock app/javascript package.json yarn.lock config/environments/production.rb config/webpack| awk '{{print $1}}') > $current_revision

if [ ! -e $previous_revision ] || ! diff $previous_revision $current_revision; then
    cp -f $current_revision $previous_revision
    rsync -ah --delete --exclude=vendor --exclude=node_modules --include=tmp/cache --include=tmp/packs --exclude=tmp ~/code/ builder:~/commcx/
    ssh builder ./commcx/build.sh
    rsync -ah --delete --exclude=vendor --exclude=node_modules --include=tmp/cache --include=tmp/packs --exclude=tmp builder:~/commcx/ ~/code/
else
    echo "assets build skipped."
fi

rsync -ah --delete --exclude=vendor --exclude=node_modules --exclude=tmp ~/code/ frontend:~/code/
ssh frontend ./code/update-frontend.sh
