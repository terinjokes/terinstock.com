#!/usr/bin/env bash
set -eo pipefail; [[ "$TRACE" ]] && set -x; set -u

deploy() {
  scp -r releases/$REL $target:/srv/terinstock/releases/$REL
  ssh $target bash -s << ENDSSH
  ln -s /srv/terinstock/releases/$REL /srv/terinstock/new
  mv -Tf /srv/terinstock/new /srv/terinstock/current
ENDSSH
}

deploy "$@"
