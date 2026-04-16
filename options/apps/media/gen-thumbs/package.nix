# gen-thumbs script package
#
# Queues image and video files with tumblerd via D-Bus using the default
# scheduler so thumbnails land in ~/.cache/thumbnails/ before Thunar opens
# the directory. Avoids the per-file network reads that stall the UI when
# browsing remote SMB shares.
#---------------------------------------------------------------------------------------------------
{ writeShellScriptBin }:

writeShellScriptBin "gen-thumbs" ''
  set -euo pipefail

  usage() {
      echo "Usage: gen-thumbs [-w] <directory>"
      echo ""
      echo "Recursively pre-generates thumbnails for all images and videos under"
      echo "<directory> by queuing them with tumblerd via D-Bus. Thumbnails land"
      echo "in ~/.cache/thumbnails/<flavor>/ matching Thunar's current zoom level."
      echo ""
      echo "Supported formats:"
      echo "  Images: jpg jpeg png gif webp bmp tiff tif heic avif jxl"
      echo "  Video:  mp4 mkv mov avi wmv m4v flv webm"
      echo ""
      echo "Options:"
      echo "  -w, --watch   Stay alive and print progress until tumblerd finishes"
      echo "  -h, --help    Show this help"
  }

  WATCH=false
  DIR=""
  for arg in "$@"; do
      case "$arg" in
          -h|--help)  usage; exit 0 ;;
          -w|--watch) WATCH=true ;;
          -*)         echo "Unknown option: $arg"; usage; exit 1 ;;
          *)          DIR="$arg" ;;
      esac
  done

  if [[ -z "$DIR" ]]; then
      usage
      exit 0
  fi

  # Use pwd -L (logical path) to preserve symlinks — Thunar generates thumbnail
  # keys from the symlink path, not the resolved physical path
  DIR="$(cd "$DIR" && pwd -L)"
  BATCH=50

  # Map Thunar's current zoom level to the thumbnail flavor it requests.
  # Icons <= 128px use "normal" (128x128), <= 256px use "large" (256x256),
  # anything larger uses "x-large" (512x512).
  zoom=$(xfconf-query -c thunar -p /last-icon-view-zoom-level 2>/dev/null || echo "THUNAR_ZOOM_LEVEL_100_PERCENT")
  case "$zoom" in
      *_25_*|*_38_*|*_50_*|*_75_*|*_100_*|*_150_*|*_200_*) FLAVOR="normal" ;;
      *_250_*|*_300_*|*_400_*)                               FLAVOR="large" ;;
      *)                                                      FLAVOR="x-large" ;;
  esac
  THUMB_DIR="$HOME/.cache/thumbnails/$FLAVOR"
  echo "Thumbnail flavor: $FLAVOR (Thunar zoom: $zoom)"

  # Timestamp marker — set before queuing so the watch loop can count only
  # thumbnails produced by this run (find -newer STAMP)
  STAMP=$(mktemp)
  trap 'rm -f "$STAMP"' EXIT

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
  cached=0
  uris=()
  mimes=()

  flush_batch() {
      [[ ''${#uris[@]} -eq 0 ]] && return
      local uri_gv="[" mime_gv="[" sep="" u m
      for i in "''${!uris[@]}"; do
          u="''${uris[$i]}"
          m="''${mimes[$i]}"
          uri_gv+="$sep\"$u\""
          mime_gv+="$sep\"$m\""
          sep=", "
      done
      uri_gv+="]"; mime_gv+="]"
      gdbus call --session \
          --dest org.freedesktop.thumbnails.Thumbnailer1 \
          --object-path /org/freedesktop/thumbnails/Thumbnailer1 \
          --method org.freedesktop.thumbnails.Thumbnailer1.Queue \
          "$uri_gv" "$mime_gv" "'$FLAVOR'" "'default'" "uint32 0" >/dev/null || true
      uris=(); mimes=()
  }

  # Percent-encode a file path for use in a file:// URI.
  # Encodes everything except unreserved chars (letters, digits, ._~) and /.
  urlencode() {
      local str="$1" encoded="" i c hex
      for (( i=0; i<''${#str}; i++ )); do
          c="''${str:$i:1}"
          case "$c" in
              [a-zA-Z0-9._~/-]) encoded+="$c" ;;
              *) printf -v hex '%%%02X' "'$c"
                 encoded+="$hex" ;;
          esac
      done
      printf '%s' "$encoded"
  }

  # Infer MIME type from extension — avoids reading file contents over the network
  mime_from_ext() {
      case "''${1,,}" in
          *.jpg|*.jpeg) echo "image/jpeg" ;;
          *.png)        echo "image/png" ;;
          *.gif)        echo "image/gif" ;;
          *.webp)       echo "image/webp" ;;
          *.bmp)        echo "image/bmp" ;;
          *.tiff|*.tif) echo "image/tiff" ;;
          *.heic)       echo "image/heic" ;;
          *.avif)       echo "image/avif" ;;
          *.jxl)        echo "image/jxl" ;;
          *.mp4)        echo "video/mp4" ;;
          *.mkv)        echo "video/x-matroska" ;;
          *.mov)        echo "video/quicktime" ;;
          *.avi)        echo "video/x-msvideo" ;;
          *.wmv)        echo "video/x-ms-wmv" ;;
          *.m4v)        echo "video/x-m4v" ;;
          *.flv)        echo "video/x-flv" ;;
          *.webm)       echo "video/webm" ;;
          *)            echo "application/octet-stream" ;;
      esac
  }

  for file in "''${files[@]}"; do
      uri="file://$(urlencode "$file")"
      hash=$(printf '%s' "$uri" | md5sum | cut -d' ' -f1)
      # Skip files whose thumbnail already exists — avoids re-queuing and
      # keeps the watch counter accurate on repeat runs
      if [[ -f "$THUMB_DIR/$hash.png" ]]; then
          cached=$(( cached + 1 ))
          continue
      fi
      mime="$(mime_from_ext "$file")"
      uris+=("$uri")
      mimes+=("$mime")
      count=$(( count + 1 ))
      if [[ ''${#uris[@]} -ge $BATCH ]]; then
          flush_batch
          echo "Queued $count/$total..."
      fi
  done

  echo "Skipped $cached already-cached files."

  if [[ $count -eq 0 ]]; then
      echo "All $total files already cached."
      exit 0
  fi

  flush_batch
  echo "Done — queued $count files. Tumblerd is processing in the background."

  if $WATCH; then
      echo "Watching progress..."
      prev=-1
      stall=0
      iters=0
      while true; do
          # Count only thumbnails created since this run started — O(1) and
          # immune to pre-existing cached thumbnails from prior runs
          completed=$(find "$THUMB_DIR" -name "*.png" -newer "$STAMP" -type f 2>/dev/null | wc -l)
          printf "\r  Progress: %d/%d (%d%%)" "$completed" "$count" "$(( completed * 100 / count ))"
          if [[ $completed -ge $count ]]; then
              printf " -- Done!\n"
              break
          fi
          # Only count stall once tumblerd has produced at least one thumbnail;
          # before that it is still warming up
          if [[ $completed -gt 0 && $completed -eq $prev ]]; then
              stall=$(( stall + 1 ))
              if [[ $stall -ge 15 ]]; then
                  printf " -- Stopped (no progress for 30s, %d remaining)\n" "$(( count - completed ))"
                  break
              fi
          else
              stall=0
          fi
          # Hard ceiling: exit after 30 minutes regardless
          iters=$(( iters + 1 ))
          if [[ $iters -ge 900 ]]; then
              printf " -- Stopped (30 min timeout, %d remaining)\n" "$(( count - completed ))"
              break
          fi
          prev=$completed
          sleep 2
      done
  fi
''
