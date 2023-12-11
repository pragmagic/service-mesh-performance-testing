#!/usr/bin/env bash

failed_files=0
checked_files=0
for file in "$@"
do
    checked_files=$((checked_files+1))
    [ -f "$file" ] || { echo "file does not exist: $file"; failed_files=$((failed_files+1)); continue; }
    error_count="$(jq --exit-status .ErrorsDurationHistogram.Count "$file")" \
        || { echo "file structure is wrong: $file"; failed_files=$((failed_files+1)); continue; }
    [ "$error_count" = 0 ] || { echo "file containts errors: $file"; failed_files=$((failed_files+1)); }
done

[ "$failed_files" = 0 ] && (
    [ "${VALIDATE_SKIP_PRINT:-}" == "true" ] || echo "no issues found in $checked_files files"
) || (echo "files failed validation: $failed_files out of total $checked_files"; exit 1)
