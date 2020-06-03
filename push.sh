#!/bin/bash

git add --all

git commit -s -m "UpdateAt: `date '+%Y-%m-%d %H:%M:%S'`"

git push origin --all
