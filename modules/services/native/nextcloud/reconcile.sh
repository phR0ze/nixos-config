# shellcheck disable=SC2016  # jq programs are single-quoted on purpose
# Applies the declared Nextcloud groups, users and SMB External Storage mounts, see deployment note 4
# in default.nix. Only ever adds or updates: users, groups, memberships and mounts that aren't
# declared are left alone and logged.
#
# Usage: nextcloud-reconcile <desired.json> <state dir>
# - Runs as the nextcloud user, so `nextcloud-occ` executes directly without sudo
# - Passwords are read from their secret files with `jq --rawfile`, so quoting can't break the JSON
#---------------------------------------------------------------------------------------------------
desired="$1"
state="$2"
mkdir -p "$state"

occ() { nextcloud-occ --no-interaction "$@"; }
warn() { echo "warning: $*" >&2; }

# Apps and settings, see deployment note 7 in default.nix
occ app:enable files_external >/dev/null
occ background:cron >/dev/null

enabled=$(occ app:list --enabled --output=json)
while IFS= read -r a; do
  [ -z "$a" ] && continue
  if jq -e --arg a "$a" '.enabled | has($a)' <<<"$enabled" >/dev/null; then
    occ app:disable "$a" >/dev/null
    echo "disabled app $a"
  fi
done < <(jq -r '.disabledApps[]' "$desired")

while IFS=$'\t' read -r app k v; do
  occ config:app:set "$app" "$k" --value "$v" >/dev/null
done < <(jq -r '.appConfig | to_entries[] | .key as $a | .value | to_entries[] | [$a, .key, .value] | @tsv' "$desired")

# Groups
groups=$(occ group:list --output=json)
while IFS= read -r g; do
  [ -z "$g" ] && continue
  if ! jq -e --arg g "$g" 'has($g)' <<<"$groups" >/dev/null; then
    occ group:add "$g" >/dev/null
    echo "created group $g"
  fi
done < <(jq -r '.groups[]' "$desired")

# Users: created with their initial password, which is never reset afterwards. OC_PASS goes
# through the environment, never argv
users=$(occ user:list --output=json --limit=100000)
while IFS= read -r u; do
  uid=$(jq -r .uid <<<"$u")
  if ! jq -e --arg u "$uid" 'has($u)' <<<"$users" >/dev/null; then
    args=()
    dn=$(jq -r '.displayName // empty' <<<"$u")
    [ -n "$dn" ] && args+=(--display-name "$dn")
    OC_PASS="$(<"$(jq -r .passwordFile <<<"$u")")" occ user:add --password-from-env "${args[@]}" "$uid" >/dev/null
    echo "created user $uid"
  fi

  quota=$(jq -r '.quota // empty' <<<"$u")
  if [ -n "$quota" ]; then
    occ user:setting "$uid" files quota "$quota" >/dev/null
  fi
done < <(jq -c '.users[]' "$desired")

# Group memberships, re-read so newly created groups are included
groups=$(occ group:list --output=json)
while IFS=$'\t' read -r uid g; do
  if ! jq -e --arg g "$g" --arg u "$uid" '.[$g] | index($u)' <<<"$groups" >/dev/null; then
    occ group:adduser "$g" "$uid" >/dev/null
    echo "added $uid to group $g"
  fi
done < <(jq -r '.users[] | .uid as $u | .groups[] | [$u, .] | @tsv' "$desired")

users=$(occ user:list --output=json --limit=100000)
jq -r --slurpfile d "$desired" \
  'keys[] | select(. as $u | ($d[0].users | map(.uid) | index($u)) == null and $u != $d[0].adminUser)' \
  <<<"$users" | while IFS= read -r u; do warn "user $u isn't declared"; done

# Mounts: each declared mount's Nextcloud id is recorded in `<id>.id` and a hash of its spec plus
# password in `<id>.sha`. Existing mounts are updated in place, never deleted and recreated, which
# would drop their filecache and break shares
list=$(occ files_external:list --output=json)
while IFS= read -r m; do
  id=$(jq -r .id <<<"$m")
  key=$(jq -r .key <<<"$m")
  pwfile=$(jq -r .passwordFile <<<"$m")
  sha=$({ jq -cS . <<<"$m"; cat "$pwfile"; } | sha256sum | cut -d' ' -f1)

  mid=""
  [ -s "$state/$id.id" ] && mid=$(<"$state/$id.id")
  if [ -n "$mid" ] && ! jq -e --argjson id "$mid" 'any(.[]; .mount_id == $id)' <<<"$list" >/dev/null; then
    warn "mount $key (id $mid) no longer exists, recreating it"
    mid=""
  fi

  if [ -z "$mid" ]; then
    # The import file holds the password, so it lives in the 0700 RuntimeDirectory only briefly
    tmp="$RUNTIME_DIRECTORY/import.json"
    jq --rawfile pw "$pwfile" '[{
        mount_id: null,
        mount_point: .mountPoint,
        storage: "\\OCA\\Files_External\\Lib\\Storage\\SMB",
        authentication_type: "password::password",
        configuration: (.configuration + { password: ($pw | rtrimstr("\n")) }),
        options: .options,
        applicable_users: .users,
        applicable_groups: .groups
      }]' <<<"$m" >"$tmp"
    before=$(jq '[.[].mount_id]' <<<"$list")
    occ files_external:import "$tmp" >/dev/null
    rm -f "$tmp"

    list=$(occ files_external:list --output=json)
    mid=$(jq -r --argjson before "$before" '([.[].mount_id] - $before)[0] // empty' <<<"$list")
    if [ -z "$mid" ]; then
      echo "error: importing mount $key didn't create a new mount" >&2
      exit 1
    fi
    echo "$mid" >"$state/$id.id"
    echo "$sha" >"$state/$id.sha"
    echo "created mount $key (id $mid)"
    continue
  fi

  [ "$(cat "$state/$id.sha" 2>/dev/null)" = "$sha" ] && continue

  while IFS=$'\t' read -r k v; do
    occ files_external:config "$mid" "$k" "$v" >/dev/null
  done < <(jq -r '.configuration | to_entries[] | [.key, (.value | tostring)] | @tsv' <<<"$m")
  # Briefly visible in /proc while it runs: occ only takes the value as an argument
  occ files_external:config "$mid" password "$(<"$pwfile")" >/dev/null

  while IFS=$'\t' read -r k v; do
    occ files_external:option "$mid" "$k" "$v" >/dev/null
  done < <(jq -r '.options | to_entries[] | [.key, (.value | tostring)] | @tsv' <<<"$m")

  # Applicability as add/remove deltas in one call. Clearing it first would leave the mount briefly
  # visible to everyone, since an empty applicable list means all users
  current=$(jq --argjson id "$mid" '.[] | select(.mount_id == $id)' <<<"$list")
  args=()
  while IFS= read -r x; do if [ -n "$x" ]; then args+=(--add-user "$x"); fi; done \
    < <(jq -rn --argjson c "$current" --argjson m "$m" '($m.users - $c.applicable_users)[]')
  while IFS= read -r x; do if [ -n "$x" ]; then args+=(--remove-user "$x"); fi; done \
    < <(jq -rn --argjson c "$current" --argjson m "$m" '($c.applicable_users - $m.users)[]')
  while IFS= read -r x; do if [ -n "$x" ]; then args+=(--add-group "$x"); fi; done \
    < <(jq -rn --argjson c "$current" --argjson m "$m" '($m.groups - $c.applicable_groups)[]')
  while IFS= read -r x; do if [ -n "$x" ]; then args+=(--remove-group "$x"); fi; done \
    < <(jq -rn --argjson c "$current" --argjson m "$m" '($c.applicable_groups - $m.groups)[]')
  if [ ${#args[@]} -gt 0 ]; then
    occ files_external:applicable "$mid" "${args[@]}" >/dev/null
  fi

  echo "$sha" >"$state/$id.sha"
  echo "updated mount $key (id $mid)"
done < <(jq -c '.mounts[]' "$desired")

# Mounts that were declared once but no longer are
for f in "$state"/*.id; do
  [ -e "$f" ] || continue
  id=$(basename "$f" .id)
  if ! jq -e --arg id "$id" 'any(.mounts[]; .id == $id)' "$desired" >/dev/null; then
    warn "mount $id (id $(<"$f")) is no longer declared, delete it with 'nextcloud-occ files_external:delete $(<"$f")' and remove $f"
  fi
done
