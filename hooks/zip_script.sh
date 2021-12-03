#!/usr/bin/env bash

set -Eeuo pipefail

git_root=$(git rev-parse --show-toplevel)

script_name=$(basename "$(find "${git_root}/" -name "*.py" | head -n1)" | cut -d. -f1)

if [ -f "${git_root}/${script_name}.zip" ]; then
  #rm "${git_root}/${script_name}.zip"
  echo "Woulda deleted"
fi

cd "${git_root}"
zip -r "${script_name}.zip" "${git_root}/${script_name}.py"

git add "${script_name}.zip"
