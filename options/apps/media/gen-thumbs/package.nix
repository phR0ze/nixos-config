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

  usage() {
      echo "Usage: gen-thumbs [-w] <directory>"
      echo ""
      echo "Recursively pre-generates thumbnails for all images and videos under"
      echo "<directory> by queuing them with tumblerd via D-Bus. Thumbnails land"
      echo "in ~/.cache/thumbnails/large/ so Thunar finds them already cached."
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

  DIR="$(realpath "$DIR")"
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

  # Temp file used as a timestamp reference for the watch loop
  STAMP=$(mktemp)
  trap 'rm -f "$STAMP"' EXIT

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

  if $WATCH; then
      echo "Watching progress..."
      prev=0
      stall=0
      while true; do
          completed=$(find "$HOME/.cache/thumbnails/large/" -name "*.png" -newer "$STAMP" -type f 2>/dev/null | wc -l)
          printf "\r  Progress: %d/%d (%d%%)" "$completed" "$count" "$(( completed * 100 / count ))"
          if [[ $completed -ge $count ]]; then
              printf " -- Done!\n"
              break
          fi
          if [[ $completed -eq $prev ]]; then
              (( stall++ ))
              if [[ $stall -ge 15 ]]; then
                  printf " -- Stopped (no progress for 30s, %d remaining)\n" "$(( count - completed ))"
                  break
              fi
          else
              stall=0
          fi
          prev=$completed
          sleep 2
      done
  fi
''
