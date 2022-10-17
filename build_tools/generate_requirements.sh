#!/bin/bash

set -e
set -x

PYTHON_INTERPRETER="python3.8"

cd "$(bazel info workspace)"
if [[ -f requirements_lock.txt ]]; then
  rm requirements_lock.txt
fi

_ARGS=(
  --allow-unsafe
  --generate-hashes
  "--output-file=requirements_lock.txt"
  requirements.txt
)
${PYTHON_INTERPRETER} -m piptools compile "${_ARGS[@]}"
