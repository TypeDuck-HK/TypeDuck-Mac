#!/usr/bin/env bash

BUNDLE_IDENTIFIER='hk.eduhk.inputmethod.TypeDuck'
APP_VERSION='0.6.0'

INSTALL_LOCATION='/Library/Input Methods'

pkgbuild \
    --info PackageInfo \
    --root "app" \
    --component-plist TypeDuckComponent.plist \
    --identifier "${BUNDLE_IDENTIFIER}" \
    --version "${APP_VERSION}" \
    --install-location "${INSTALL_LOCATION}" \
    --scripts "scripts" \
    TypeDuck.pkg
