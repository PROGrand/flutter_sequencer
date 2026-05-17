#!/bin/bash

flutter clean
find . -name ".dart_tool" -exec rm -fR {} \;
find . -name "pubspec.lock" -exec rm {} \;
find . -name "pubspec_overrides.yaml" -exec rm {} \;
find . -name "build" -exec rm -fR {} \;
flutter pub get
