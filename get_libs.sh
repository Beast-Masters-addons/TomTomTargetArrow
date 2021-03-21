#!/usr/bin/env bash
curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- -g 1.13.6 -c -d -z
mv .release/TomTomTargetArrow/libs .