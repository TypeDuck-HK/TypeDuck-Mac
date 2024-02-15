#!/usr/bin/env bash

BUNDLE_IDENTIFIER='hk.eduhk.inputmethod.TypeDuck'
APP_VERSION='1.0.0'
INSTALL_LOCATION='/Library/Input Methods'

pkgbuild \
    --min-os-version 12.0 \
    --compression latest \
    --identifier "${BUNDLE_IDENTIFIER}" \
    --version "${APP_VERSION}" \
    --install-location "${INSTALL_LOCATION}" \
    --info PackageInfo \
    --component-plist TypeDuckComponent.plist \
    --root "app" \
    --scripts "scripts" \
    TypeDuck.pkg
