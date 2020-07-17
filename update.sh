#!/bin/bash
set -eu
source /etc/profile.d/nvm.sh
export RAILS_ENV=production

nvm use 12
for cmds in bundle yarn;do if ! type ${cmds} 2>/dev/null 1>/dev/null;then echo "${cmds}: Not found";exit 1;fi;done

cd `dirname $0`

bundle check --path=vendor/bundle || bundle install --path=vendor/bundle --without development test --clean --retry=3 --jobs=5
pkill -u $(id -u) -f code -TSTP

git fetch --all --prune
git merge --no-commit --progress upstream/master

ret=$?
if [ $ret -ne 0 ];then
echo "Merge error"
git merge --abort
pkill -u $(id -u) -f code
exit 1
fi

git merge --abort && git merge --no-edit --progress upstream/master
git push -u origin comm.cx --force

current_revision=BUNDLE_REV
previous_revision=public/BUNDLE_REV

git rev-parse $(git log --oneline -n 1 Gemfile Gemfile.lock | awk '{{print $1}}') > $current_revision

if [ ! -e $previous_revision ] || ! diff $previous_revision $current_revision; then
    cp -f $current_revision $previous_revision
    bundle check --path=vendor/bundle || bundle install --path=vendor/bundle --without development test --clean --retry=3 --jobs=5
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

bin/tootctl cache clear
pkill -u $(id -u) -f code
rsync -ah --delete --exclude=vendor --exclude=node_modules --exclude=tmp ~/code/ frontend:~/code/
ssh frontend ./code/update-frontend.sh
