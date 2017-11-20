#/bin/bash
set -ev
export TZ='Asia/Shanghai'

npm install hexo-cli -g

npm install

git config --global user.email "yaku.mioto@gmail.com"
git config --global user.name "yakumioto"

hexo clean
hexo generate

git clone -b master git@github.com:yakumioto/yakumioto.github.io.git .deploy_git

$(cd .deploy_git && mv .git/ ../public/)

cd ./public

git add --all

git commit -m "Site updated: `date +"%Y-%m-%d %H:%M:%S"`"

git push origin master:master --force --quiet