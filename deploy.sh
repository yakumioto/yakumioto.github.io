#/bin/bash
set -ev
export TZ='Asia/Shanghai'

git config --global user.email "yaku.mioto@gmail.com"
git config --global user.name "yakumioto"

hexo clean && hexo d -g
