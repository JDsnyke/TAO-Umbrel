#!/usr/bin/env sh
# Real umbrelOS ships `rugix-ctrl` for OS partition updates. Plain Docker has no Rugix stack;
# umbreld still invokes this binary during startup — exit successfully so the daemon can continue.
exit 0
