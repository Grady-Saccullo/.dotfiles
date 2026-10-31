#!/bin/bash -e

# Re-signs every ad-hoc signed app in <apps dir> with the code-signing identity named <identity>
# (./README.md), and reports the ad-hoc signed apps in each <report dir>, which it cannot sign.
if [[ $# -lt 2 ]]; then
	echo "usage: sign-apps <identity> <apps dir> [<report dir>...]" >&2
	exit 2
fi
identity=$1
apps_dir=$2
shift 2

# Developer-signed apps are never touched: their entitlements only work with their own signature.
function ad_hoc() { codesign -dvv "$1" 2>&1 | grep -qx 'Signature=adhoc'; }

signable=()
for app in "$apps_dir"/*.app; do
	if [[ -d $app ]] && ad_hoc "$app"; then signable+=("$app"); fi
done

status=0
if [[ ${#signable[@]} -gt 0 ]]; then
	if ! security find-identity -p codesigning | grep -qF "\"$identity\""; then
		echo "codesign: no code-signing identity named \"$identity\" in the keychain; run \`nix run .#codesign-setup <host>\` in your flake to create it" >&2
		status=1
	else
		for app in "${signable[@]}"; do
			if output=$(codesign --force --deep --preserve-metadata=entitlements --sign "$identity" "$app" 2>&1); then
				echo "codesign: signed $app"
			else
				printf 'codesign: could not sign %s, so it keeps its ad-hoc signature:\n%s\n' "$app" "$output" >&2
				status=1
			fi
		done
	fi
fi

for dir in "$@"; do
	for app in "$dir"/*.app; do
		if [[ -d $app ]] && ad_hoc "$app"; then
			echo "codesign: $app is ad-hoc signed and installed system-wide, where it cannot be re-signed, so macOS forgets its permissions whenever it is rebuilt; install it with home-manager to have it signed" >&2
		fi
	done
done
exit "$status"
