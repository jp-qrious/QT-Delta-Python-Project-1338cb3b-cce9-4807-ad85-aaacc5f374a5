#!/bin/bash
set -e
set -x

python -m venv "/opt/venv" --clear
. /opt/venv/bin/activate
pip install wheel
poetry install

case "$1" in
bash)
    bash #-c "${@:2}"
    ;;
test)
    coverage erase
    coverage run --branch -m pytest "${@:2}"
    coverage xml -i -o coverage/coverage.xml
    ;;
fmt)
    isort src tests "${@:2:2}" # TODO: hard coding isort to avoid imported packages
    black ${PWD} "${@:4}"
    ;;
lint)
    flake8 ${PWD}
    mypy src
    ;;
docs)
    cd docs/
    sphinx-apidoc -o source/modules/ ../project
    cd -
    sphinx-build -b html docs/source docs/build
    ;;
*)
    exec "$@"
    ;;
esac
