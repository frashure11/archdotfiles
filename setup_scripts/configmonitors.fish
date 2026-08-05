#!/usr/bin/env fish
# Auto-detect monitors, pick best mode for each, write hl.monitor({...}) blocks
# into monitors.lua.
#
# Scale handling: a detected monitor keeps its previous scale if a block for
# the same output name already exists; otherwise it inherits the scale from
# an existing block whose resolution matches; otherwise it defaults to 1.
# No prompts — this must always produce a usable config, even after a
# hardware change, without blocking on input.
#
# A block with output = "" is treated as a fallback/default rule and is left
# untouched. All other existing hl.monitor blocks are dropped and rebuilt
# from the current detection.

set -l config "$HOME/.config/hypr/monitors.lua"

# --- sanity checks ---
if not test -f "$config"
    echo "Config not found: $config" >&2
    exit 1
end
if not command -q hyprctl
    echo "hyprctl not found (is Hyprland running?)" >&2
    exit 1
end
if not command -q jq
    echo "jq not found (install with: sudo pacman -S jq)" >&2
    exit 1
end

# --- detect monitors: best mode per monitor, positioned left-to-right ---
# tab-separated: name, WxH, refresh(rounded, no decimals), x-offset
set -l detected (hyprctl monitors all -j | jq -r '
    reduce .[] as $m ({x:0, lines:[]};
        ($m.availableModes[0] | capture("(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)Hz")) as $mode |
        {
            x: (.x + ($mode.w | tonumber)),
            lines: (.lines + ["\($m.name)\t\($mode.w)x\($mode.h)\t\(($mode.r|tonumber)+0.5|floor)\t\(.x)"])
        }
    ) | .lines[]
')

if test -z "$detected"
    echo "No monitors detected." >&2
    exit 1
end

echo "Detected monitor configuration:"
for d in $detected
    printf '  %s\n' (string replace -a \t ' ' -- $d)
end

# --- pass 1: record existing hl.monitor blocks that target a specific output ---
# (output = "" fallback blocks are intentionally skipped here)
set -l existing_output
set -l existing_res
set -l existing_scale

set -l in_block 0
set -l cur_output ""
set -l cur_res ""
set -l cur_scale ""

while read -l line
    if test $in_block -eq 0
        if string match -qr '^\s*hl\.monitor\(\{' -- "$line"
            set in_block 1
            set cur_output ""
            set cur_res ""
            set cur_scale ""
        end
        continue
    end
    if set -l m (string match -gr 'output\s*=\s*"([^"]*)"' -- "$line")
        set cur_output $m[1]
    else if set -l m (string match -gr 'mode\s*=\s*"([0-9]+x[0-9]+)@' -- "$line")
        set cur_res $m[1]
    else if set -l m (string match -gr 'scale\s*=\s*([0-9.]+)' -- "$line")
        set cur_scale $m[1]
    end
    if string match -qr '^\s*\}\)' -- "$line"
        if test -n "$cur_output"
            set -a existing_output $cur_output
            set -a existing_res $cur_res
            set -a existing_scale $cur_scale
        end
        set in_block 0
    end
end <"$config"

# --- pass 2: resolve each detected monitor's scale, build new blocks ---
set -l new_blocks
for d in $detected
    set -l parts (string split \t -- $d)
    set -l name $parts[1]
    set -l res $parts[2]
    set -l refresh $parts[3]
    set -l xpos $parts[4]

    set -l scale ""
    for i in (seq (count $existing_output) 2>/dev/null; or echo)
        if test "$existing_output[$i]" = "$name"
            set scale $existing_scale[$i]
            break
        end
    end
    if test -z "$scale"
        for i in (seq (count $existing_res) 2>/dev/null; or echo)
            if test "$existing_res[$i]" = "$res"
                set scale $existing_scale[$i]
                break
            end
        end
    end
    if test -z "$scale"
        set scale "1"
    end

    set -l pos (string join '' -- $xpos x0)
    set -a new_blocks "hl.monitor({
    output   = \"$name\",
    mode     = \"$res@$refresh\",
    position = \"$pos\",
    scale    = $scale,
})"
end

# --- backup ---
cp "$config" "$config.bak"

# --- pass 3: rewrite file, dropping specific-output blocks, keeping fallback
#     blocks and everything else untouched, inserting new blocks where the
#     first existing hl.monitor block used to be ---
set -l tmp (mktemp)
set -l in_block 0
set -l block_lines
set -l block_output ""
set -l inserted 0
# after a block is written (kept) or dropped, swallow the blank line(s) that
# used to separate it from its neighbor so spacing doesn't grow every run —
# we re-add our own single blank between blocks instead.
set -l skip_blanks 0

while read -l line
    if test $in_block -eq 0
        if string match -qr '^\s*hl\.monitor\(\{' -- "$line"
            set in_block 1
            set block_lines $line
            set block_output ""
            continue
        end
        if test $skip_blanks -eq 1
            if string match -qr '^\s*$' -- "$line"
                continue
            end
            set skip_blanks 0
        end
        echo "$line" >>$tmp
        continue
    end
    set -a block_lines $line
    if set -l m (string match -gr 'output\s*=\s*"([^"]*)"' -- "$line")
        set block_output $m[1]
    end
    if string match -qr '^\s*\}\)' -- "$line"
        if test -z "$block_output"
            for bl in $block_lines
                echo "$bl" >>$tmp
            end
        end
        if test $inserted -eq 0
            for i in (seq (count $new_blocks))
                echo "$new_blocks[$i]" >>$tmp
                echo "" >>$tmp
            end
            set inserted 1
        end
        set in_block 0
        set skip_blanks 1
    end
end <"$config"

if test $inserted -eq 0
    for i in (seq (count $new_blocks))
        echo "$new_blocks[$i]" >>$tmp
        echo "" >>$tmp
    end
end

mv $tmp "$config"
echo "Updated $config (backup at $config.bak)"
