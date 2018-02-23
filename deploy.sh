#/bin/bash
set -ev
export TZ='Asia/Shanghai'

git config --global user.email "yaku.mioto@gmail.com"
git config --global user.name "yakumioto"

npm install --save hexo-filter-flowchart
npm install --save hexo-filter-sequence

hexo clean && hexo d -g