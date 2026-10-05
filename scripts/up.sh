#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

vagrant.exe up
vagrant.exe ssh bastion -c "cd ~/devops_learning && git pull && make provision"
