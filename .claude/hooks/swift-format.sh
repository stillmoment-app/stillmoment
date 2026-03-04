#!/bin/bash
# Auto-format Swift files after Edit/Write
FILE_PATH=$(cat - | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" == *.swift ]]; then
  swiftformat --swiftversion 5.9 "$FILE_PATH" 2>/dev/null
fi
exit 0
