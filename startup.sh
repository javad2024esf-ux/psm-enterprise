#!/bin/bash
# Kept for backward compatibility (used by `make up`).
# Delegates to install.sh, the canonical one-click installer.
exec "$(dirname "$0")/install.sh"
