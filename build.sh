#!/bin/bash

swift build -c release
./bundle.sh
cp -r build/Upcoming.app /Applications
