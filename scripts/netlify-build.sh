#!/usr/bin/env bash
set -euo pipefail

flutter_version="${FLUTTER_VERSION:-3.44.4}"
api_base_url="${API_BASE_URL:-https://server-rho-two-45.vercel.app}"
cache_root="${NETLIFY_CACHE_DIR:-${HOME}/.cache}"
flutter_dir="${cache_root}/flutter-${flutter_version}"

if [[ ! -x "${flutter_dir}/bin/flutter" ]]; then
  mkdir -p "${cache_root}"
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "${temp_dir}"' EXIT
  archive="${temp_dir}/flutter.tar.xz"
  download_url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${flutter_version}-stable.tar.xz"

  curl --fail --location --silent --show-error "${download_url}" --output "${archive}"
  mkdir "${temp_dir}/extract"
  tar -xJf "${archive}" -C "${temp_dir}/extract"
  mv "${temp_dir}/extract/flutter" "${flutter_dir}"
fi

export PATH="${flutter_dir}/bin:${PATH}"
export PUB_CACHE="${cache_root}/pub-cache"

flutter config --no-analytics
flutter pub get
flutter build web --release --dart-define="API_BASE_URL=${api_base_url}"
