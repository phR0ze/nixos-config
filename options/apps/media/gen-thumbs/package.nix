# gen-thumbs script package
#
# Queues image and video files with tumblerd via D-Bus using the background
# scheduler so thumbnails land in ~/.cache/thumbnails/ before Thunar opens
# the directory. Avoids the per-file network reads that stall the UI when
# browsing remote SMB shares.
#---------------------------------------------------------------------------------------------------
{ writeShellScriptBin }:

writeShellScriptBin "gen-thumbs" ''
  set -euo pipefail
  DIR="$(realpath "''${1:-.}")"
  BATCH=50

  # Collect all image and video files
  mapfile -d $'\0' -t files < <(find "$DIR" -type f \( \
      -iname "*.jpg"  -o -iname "*.jpeg" -o -iname "*.png"  \
      -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.bmp"  \
      -o -iname "*.tiff" -o -iname "*.tif" -o -iname "*.heic" \
      -o -iname "*.avif" -o -iname "*.jxl"                    \
      -o -iname "*.mp4"  -o -iname "*.mkv" -o -iname "*.mov"  \
      -o -iname "*.avi"  -o -iname "*.wmv" -o -iname "*.m4v"  \
      -o -iname "*.flv"  -o -iname "*.webm"                   \
  \) -print0 2>/dev/null)

  total="''${#files[@]}"
  echo "Found $total files in $DIR"
  [[ $total -eq 0 ]] && exit 0

  count=0
  uris=()
  mimes=()

  flush_batch() {
      [[ ''${#uris[@]} -eq 0 ]] && return
      local uri_gv="[" mime_gv="[" sep="" u m
      for i in "''${!uris[@]}"; do
          u="''${uris[$i]}"
          m="''${mimes[$i]}"
          uri_gv+="$sep'$u'"
          mime_gv+="$sep'$m'"
          sep=", "
      done
      uri_gv+="]"; mime_gv+="]"
      gdbus call --session \
          --dest org.freedesktop.thumbnails.Thumbnailer1 \
          --object-path /org/freedesktop/thumbnails/Thumbnailer1 \
          --method org.freedesktop.thumbnails.Thumbnailer1.Queue \
          "$uri_gv" "$mime_gv" "'large'" "'background'" "uint32 0" >/dev/null 2>&1
      uris=(); mimes=()
  }

  for file in "''${files[@]}"; do
      uri="file://$(realpath "$file")"
      mime="$(file --mime-type -b "$file" 2>/dev/null || echo "application/octet-stream")"
      uris+=("$uri")
      mimes+=("$mime")
      (( count++ ))
      if [[ ''${#uris[@]} -ge $BATCH ]]; then
          flush_batch
          echo "Queued $count/$total..."
      fi
  done

  flush_batch
  echo "Done — queued $count files. Tumblerd is processing in the background."
''
