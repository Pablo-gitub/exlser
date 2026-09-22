#!/usr/bin/env bash
# Builds a .deb around the Flutter Linux release bundle.
#
# The bundle is self-contained: the executable, a data/ directory that must
# stay beside it, and lib/ with the plugin shared objects — including the
# libsqlite3.so that sqlite3_flutter_libs contributes, which is why the package
# does not depend on the system SQLite.
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 VERSION BUNDLE_DIR OUTPUT_DEB" >&2
  exit 2
fi

version="$1"
bundle_dir="$(readlink -f "$2")"
output_deb="$(readlink -m "$3")"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# A .deb published on GitHub carries this address to everyone who downloads it,
# so it defaults to the GitHub no-reply form rather than a personal mailbox.
maintainer="${EXLSER_DEB_MAINTAINER:-Paolo Pietrelli <Pablo-gitub@users.noreply.github.com>}"

if [[ ! -x "${bundle_dir}/Exlser" ]]; then
  echo "The bundle directory does not contain an executable Exlser binary." >&2
  exit 1
fi

if [[ ! -f "${bundle_dir}/lib/libsqlite3.so" ]]; then
  echo "The bundle is missing lib/libsqlite3.so; the app would fail on first query." >&2
  exit 1
fi

package_root="$(mktemp -d)"
trap 'rm -rf "${package_root}"' EXIT

install -d \
  "${package_root}/DEBIAN" \
  "${package_root}/opt/exlser" \
  "${package_root}/usr/bin" \
  "${package_root}/usr/share/applications" \
  "${package_root}/usr/share/icons/hicolor/512x512/apps"

cp -a "${bundle_dir}/." "${package_root}/opt/exlser/"

# Flutter's Linux runner resolves the bundle from /proc/self/exe, so the binary
# keeps finding data/ and lib/ when it is started through this symlink.
ln -s /opt/exlser/Exlser "${package_root}/usr/bin/exlser"

install -m 0644 "${repo_root}/flutter_app/web/icons/Icon-512.png" \
  "${package_root}/usr/share/icons/hicolor/512x512/apps/exlser.png"

# No MimeType is declared on purpose: the app imports through its own picker
# and ignores a file passed as an argument, so claiming the CSV/XLSX types
# would offer the user a handler that then does nothing.
cat > "${package_root}/usr/share/applications/exlser.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Exlser
Comment=Local-first spreadsheet workspace for CSV and XLSX files
Exec=/usr/bin/exlser
Icon=exlser
Terminal=false
Categories=Office;Spreadsheet;
Keywords=spreadsheet;csv;xlsx;excel;data;sql;
EOF
chmod 0644 "${package_root}/usr/share/applications/exlser.desktop"

installed_size="$(du -ks "${package_root}/opt" | cut -f1)"

cat > "${package_root}/DEBIAN/control" <<EOF
Package: exlser
Version: ${version}
Section: utils
Priority: optional
Architecture: amd64
Maintainer: ${maintainer}
Installed-Size: ${installed_size}
Depends: libgtk-3-0 (>= 3.22.0), libglib2.0-0, libstdc++6, xdg-utils
Homepage: https://exlser.com
Description: Local-first spreadsheet workspace
 Exlser turns CSV and XLSX files into persistent local datasets with filters,
 sorting, read-only SQL, charts and exports.
 .
 Everything runs on this machine: there is no server, no account and no
 telemetry, and imported data never leaves the device.
EOF

dpkg-deb --root-owner-group --build "${package_root}" "${output_deb}"
echo "Built ${output_deb}"
