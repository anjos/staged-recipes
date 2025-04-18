#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Avoid limitations with install_name_tool rpath re-writing
if [[ "$(uname)" == "Darwin" ]]; then
  export CXXFLAGS="${CXXFLAGS} -Wl,-headerpad_max_install_names"
  export LDFLAGS="${LDFLAGS} -headerpad_max_install_names"
fi

# Fix package.json so it can bootstrap itself
# Remove preinstall script because it needs devDependencies that need to be installed
# with npm install
# Remove compile command from post install script so we don't try to transpile
# typescript again
mv package.json package.json.bak
jq "del(.scripts.preinstall)" package.json.bak > package.json
sed -i 's/setup compile sh:relink/setup sh:relink/' package.json

# Install dependencies without running postinstall
yarn config set enableScripts false
yarn install

# Remove tsc package and replace with typescript so we can transpile typescript
# and then manually run compile script
yarn remove tsc
yarn add typescript --dev
yarn run compile

# Add fast-glob as a production dependency
yarn add fast-glob

# Create package archive
rm -f tree-sitter-fish.wasm
yarn pack

# Symlink run-s from npm-run-all to ${SRC_DIR}/bin and add this folder to path
ln -sf ${SRC_DIR}/node_modules/npm-run-all/bin/run-s/index.js ${SRC_DIR}/bin/run-s
export PATH="${SRC_DIR}/bin:${PATH}"

# Install the packed tgz globally
npm install -ddd --global --build-from-source ${SRC_DIR}/package.tgz

# Create license report for dependencies
yarn licenses generate-disclaimer > third-party-licenses.txt
