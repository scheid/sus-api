#!/usr/bin/env bash

# note that we need the .leaf extension because leaf will automatically add '.leaf' to the value for an embed 
sass scss/app.scss:./app.css.leaf --scss --style compressed