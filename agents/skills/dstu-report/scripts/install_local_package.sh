#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd -- "${script_dir}/.." && pwd)"
package_dir="${skill_dir}/assets/package"
manifest_path="${package_dir}/typst.toml"

if ! command -v typst >/dev/null 2>&1; then
  echo "typst is required but was not found in PATH" >&2
  exit 1
fi

if [[ ! -f "${manifest_path}" ]]; then
  echo "package manifest not found at ${manifest_path}" >&2
  exit 1
fi

package_name="$(sed -n 's/^name = "\(.*\)"$/\1/p' "${manifest_path}" | head -n 1)"
package_version="$(sed -n 's/^version = "\(.*\)"$/\1/p' "${manifest_path}" | head -n 1)"

if [[ -z "${package_name}" || -z "${package_version}" ]]; then
  echo "failed to read package name/version from ${manifest_path}" >&2
  exit 1
fi

typst_info_output="$(typst info 2>&1)"
package_path_line="$(awk '/^  Package path/{print $NF; exit}' <<< "${typst_info_output}")"
if [[ -z "${package_path_line}" ]]; then
  echo "failed to determine Typst package path from 'typst info'" >&2
  exit 1
fi

target_dir="${package_path_line}/local/${package_name}/${package_version}"
mkdir -p "$(dirname -- "${target_dir}")"
rm -rf "${target_dir}"
mkdir -p "${target_dir}"
cp -R "${package_dir}/." "${target_dir}/"

echo "Installed local Typst package:"
echo "  source: ${package_dir}"
echo "  target: ${target_dir}"
echo
echo "Use it from projects as:"
echo "  #import \"@local/${package_name}:${package_version}\": template"
