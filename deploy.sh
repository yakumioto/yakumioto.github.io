#/bin/bash
set -ev
export TZ='Asia/Shanghai'

npm install hexo-cli -g

npm install

git config --global user.email "yaku.mioto@gmail.com"
git config --global user.name "yakumioto"

hexo g -d