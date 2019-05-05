#!/bin/bash
set -eu
source /etc/profile.d/nvm.sh
export RAILS_ENV=production

nvm use lts/dubnium
for cmds in bundle yarn;do if ! type ${cmds} 2>/dev/null 1>/dev/null;then echo "${cmds}: Not found";exit 1;fi;done

cd `dirname $0`

rsync -ah --delete --exclude=vendor --exclude=node_modules --include=tmp/cache --include=tmp/packs --exclude=tmp ~/code/ builder:~/commcx/
ssh builder ./commcx/build.sh
rsync -ah --delete --exclude=vendor --exclude=node_modules --include=tmp/cache --include=tmp/packs --exclude=tmp builder:~/commcx/ ~/code/
rsync -ah --delete --exclude=vendor --exclude=node_modules --exclude=tmp ~/code/ frontend:~/code/
ssh frontend ./code/update-frontend.sh
