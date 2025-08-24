#!/usr/bin/env bash
curl -s https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh | bash -s -- -g wrath -c -d -z
rsync -av --del .release/TomTomTargetArrow/libs .