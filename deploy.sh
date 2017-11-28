#/bin/bash
set -ev
export TZ='Asia/Shanghai'

npm install hexo -g 

npm install 

hexo clean

hexo d -g