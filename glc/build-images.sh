#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage:
  sh ./build-images.sh [-i IMAGE] [-v VERSION] [-f DOCKERFILE]

Options:
  -i, --image       Image repository/name, default: chenjc/glc
  -v, --version     Image version tag, default: read from ver/version.go
  -f, --dockerfile  Dockerfile path, default: Dockerfile
  -h, --help        Show this help message

Examples:
  sh ./build-images.sh
  sh ./build-images.sh -v v2.0.0
  sh ./build-images.sh -i chenjc/glc -v v2.0.0 -f Dockerfile.1
EOF
}

default_version() {
  awk -F'"' '/const VERSION = / { print $2; exit }' ver/version.go
}

IMAGE_NAME="chenjc/glc"
VERSION="$(default_version)"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    -i|--image)
      [ "$#" -ge 2 ] || { echo "Missing value for $1" >&2; exit 1; }
      IMAGE_NAME="$2"
      shift 2
      ;;
    -v|--version)
      [ "$#" -ge 2 ] || { echo "Missing value for $1" >&2; exit 1; }
      VERSION="$2"
      shift 2
      ;;
    -f|--dockerfile)
      [ "$#" -ge 2 ] || { echo "Missing value for $1" >&2; exit 1; }
      DOCKERFILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$VERSION" ]; then
  echo "Unable to determine version. Use -v to specify one." >&2
  exit 1
fi

WEB_TAG="${IMAGE_NAME}:web-${VERSION}"
FINAL_TAG="${IMAGE_NAME}:${VERSION}"
LATEST_TAG="${IMAGE_NAME}:latest"

echo "Building ${WEB_TAG} ..."
docker build -f "${DOCKERFILE}" --target node-builder -t "${WEB_TAG}" .

echo "Building ${FINAL_TAG} ..."
docker build -f "${DOCKERFILE}" -t "${FINAL_TAG}" -t "${LATEST_TAG}" .

echo "Done."
echo "Generated images:"
echo "  ${WEB_TAG}"
echo "  ${FINAL_TAG}"
echo "  ${LATEST_TAG}"
