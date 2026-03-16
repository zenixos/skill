#!/usr/bin/env nu
# description: List installed and available skills

use lib/skill-config.nu *
use lib/skill-discover.nu
use ../lib/vcs.nu
use ../lib/style.nu

# Format skill line with aligned columns
def format-skill [name: string, type: string, version: string, pad: int] {
    let type_pad = "" | fill -c ' ' -w (6 - ($type | str length))
    let name_pad = "" | fill -c ' ' -w ($pad - ($name | str length))
    $"  ($type)($type_pad) | ($name)($name_pad)($version)"
}

# Get xenix version from VERSION file
def xenix-version [] {
    try { open ($ROOT_DIR | path join "VERSION") | str trim } catch { "" }
}

# List all skills with progressive output
export def main [] {
    let installed = skill-discover
    let installed_names = $installed | get name
    let exclude = ["zenix" "xenix" "system"]
    
    # Calculate padding for alignment
    let max_len = $installed | each {|s| $s.name | str length } | math max | default 20
    let pad = $max_len + 2
    
    # Header with xenix version
    let ver = xenix-version
    let header = if ($ver | is-empty) { "zenixos" } else { $"zenixos: ($ver)" }
    print (style header $header)
    print ""
    
    # Installed (instant)
    print (style header "Installed")
    if ($installed | is-empty) {
        print "  (none)"
    } else {
        $installed | each {|s|
            print (format-skill $s.name $s.type (style dim $s.version) $pad)
        }
    }
    
    # Fetch remote (progressive)
    let remote = try {
        vcs list-repos $GITHUB_ORG
        | where {|r| $r.name not-in $exclude }
    } catch { [] }
    
    if ($remote | is-empty) { return }
    
    # Available (not installed)
    let available = $remote | where {|r| $r.name not-in $installed_names }
    if ($available | is-not-empty) {
        print ""
        print (style header "Available")
        let avail_pad = $available | each {|r| $r.name | str length } | math max | default 20
        let avail_pad = [($avail_pad + 2) $pad] | math max
        
        $available | each {|r|
            let type = if $r.name in $CORE_SKILLS { "system" } else { "plugin" }
            print (format-skill $r.name $type (style dim $r.version) $avail_pad)
        }
    }
    
    # Updates (compare versions)
    let updates = $installed | each {|s|
        let remote_ver = $remote | where name == $s.name | get -o 0.version | default ""
        if ($remote_ver | is-not-empty) and ($remote_ver != $s.version) {
            { name: $s.name, current: $s.version, latest: $remote_ver }
        }
    } | compact
    
    if ($updates | is-not-empty) {
        print ""
        print (style header "Updates")
        let ver_info = $updates | each {|u| $"($u.current) -> ($u.latest)" } | str join ", "
        let ver_padding = "" | fill -c ' ' -w $pad
        print $"($ver_padding)(style dim $ver_info)"
        print ""
        let skill_names = $updates | get name | str join " "
        print $"Run: (style ok $'skill update ($skill_names)')"
    }
}
