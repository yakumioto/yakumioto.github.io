#/bin/bash

git add --all

git commit -m "UpdateAt: $(date "+%Y-%m-%d %H:%M:%S")"

git push origin master