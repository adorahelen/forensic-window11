#!/usr/bin/env bash
# extract_profile_artifacts.sh
# 사용법: ./extract_profile_artifacts.sh
# 필요: fls, icat (SleuthKit)

IMAGE="secondImaging.raw"
OFFSET=239616
ROOT_INODE="189787-144-6"   # Default 프로필 inode (변경 가능)
OUTDIR="extracted"

mkdir -p "$OUTDIR"

# fls 출력에서 "type inode:  name" 형태에서 inode token과 name을 추출하는 헬퍼
# 입력: inodeToken (예: 189787-144-6), outPath (filesystem-relative path)
recurse() {
  local inode_token="$1"
  local outpath="$2"

  # Ensure directory exists
  mkdir -p "$outpath"

  # 리스트 디렉토리 항목
  # use -p to show full path? We use inode listing for that directory.
  fls -o "$OFFSET" "$IMAGE" "$inode_token" 2>/dev/null | while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Example lines:
    # d/d 190180-144-1:	Cache
    # r/r 190179-128-3:	History
    # r/r 190403-128-4:	Account Web Data
    # parse type, inode, name (name may contain tabs/spaces)
    # We'll split at first colon ":" to separate inode section and name
    # first part contains "d/d 190180-144-1" or "r/r 190179-128-3"
    left="${line%%:*}"
    right="${line#*:}"
    # trim whitespace
    left="$(echo "$left" | tr -s ' ' | sed 's/^ *//;s/ *$//')"
    name="$(echo "$right" | sed 's/^[[:space:]\t]*//;s/[[:space:]\t]*$//')"

    # from left get the inode token (the second field)
    inode_field="$(echo "$left" | awk '{print $2}')"
    type_field="$(echo "$left" | awk '{print $1}')"

    # sanitize name for filesystem: replace "/" with "_"
    safe_name="$(echo "$name" | sed 's#[/\\]#_#g')"

    if [[ "$type_field" == "d/d" ]]; then
      # directory: recurse
      subdir="$outpath/$safe_name"
      echo "[DIR ] $name -> inode=$inode_field -> $subdir"
      recurse "$inode_field" "$subdir"
    else
      # regular file (r/r, r/-, etc.) -> extract via icat
      # output file name include inode prefix to avoid collisions
      outfile="$outpath/${inode_field}__${safe_name}"
      echo "[FILE] $name -> inode=$inode_field -> $outfile"
      # icat may fail on special entries; redirect stderr
      icat -o "$OFFSET" "$IMAGE" "$inode_field" > "$outfile" 2>/dev/null || echo "  [WARN] icat failed for $inode_field"
    fi
  done
}

echo "Starting extraction: IMAGE=$IMAGE OFFSET=$OFFSET ROOT_INODE=$ROOT_INODE OUTDIR=$OUTDIR"
recurse "$ROOT_INODE" "$OUTDIR"
echo "Extraction complete. Files saved under: $OUTDIR"
