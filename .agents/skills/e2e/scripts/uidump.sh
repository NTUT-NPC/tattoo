#!/usr/bin/env bash
# Dump the connected Android device's UI accessibility tree to an XML file
# and print a compact summary of the elements worth tapping or reading.
# Streams via `exec-out` so no /sdcard round-trip + adb pull is needed.
#
# Usage: uidump.sh [output_path]
#   default output: /tmp/ui.xml
#   set ANDROID_SERIAL=<serial> when more than one device is attached
set -euo pipefail

out="${1:-/tmp/ui.xml}"
# `uiautomator dump /dev/tty` writes the XML to stdout but appends a status
# line ("UI hierchary dumped to: /dev/tty" — typo is upstream in AOSP).
adb exec-out uiautomator dump /dev/tty \
  | sed 's|UI hierchary dumped to: /dev/tty||' \
  > "$out"

echo "wrote: $out"
echo "elements:"
awk '
  function compact(s) {
    gsub(/[[:space:]]+/, " ", s)
    sub(/^ /, "", s); sub(/ $/, "", s)
    if (length(s) > 120) s = substr(s, 1, 117) "..."
    return s
  }
  function decode(s) {
    gsub(/&lt;/, "<", s)
    gsub(/&gt;/, ">", s)
    gsub(/&quot;/, "\"", s)
    gsub(/&apos;/, "'\''", s)
    gsub(/&amp;/, "\\&", s)  # must be last
    return s
  }
  # Escape backslash and double-quote so values stay unambiguous when wrapped
  # in `text="..."` / `desc="..."`. Char-by-char to avoid gsub backslash soup.
  function escape(s,   out, i, c) {
    out = ""
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c == "\\")      out = out "\\\\"
      else if (c == "\"") out = out "\\\""
      else                out = out c
    }
    return out
  }
  # Extract attribute value; matches " name=\"...\"" with a leading space so
  # short names like "text" or "clickable" do not match inside "content-desc"
  # or "long-clickable".
  function attr(name,   pat, val, head) {
    pat = "[[:space:]]" name "=\"[^\"]*\""
    if (match($0, pat)) {
      head = length(name) + 3                    # space + name + ="
      val = substr($0, RSTART + head, RLENGTH - head - 1)
      return val
    }
    return ""
  }
  { buf = buf $0 }
  END {
    gsub(/<node /, "\n<node ", buf)
    m = split(buf, lines, "\n")
    nstates = split("clickable scrollable selected focused password", state_names, " ")
    for (i = 1; i <= m; i++) {
      $0 = lines[i]
      if ($0 !~ /^<node /) continue

      text = decode(attr("text"))
      desc = decode(attr("content-desc"))
      bounds = attr("bounds")
      cls = attr("class")
      np = split(cls, parts, ".")
      cls = parts[np]

      states = ""
      for (j = 1; j <= nstates; j++) {
        if (index($0, " " state_names[j] "=\"true\"")) {
          states = states (states ? " " : "") state_names[j]
        }
      }

      if (text == "" && desc == "" && states == "") continue

      line = "  " bounds " " cls
      if (text != "")   line = line " text=\"" escape(compact(text)) "\""
      if (desc != "")   line = line " desc=\"" escape(compact(desc)) "\""
      if (states != "") line = line " " states
      print line
    }
  }
' "$out"
