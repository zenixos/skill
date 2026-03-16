#!/usr/bin/env nu
# description: List installed and available skills

use lib/skill-config.nu *
use lib/skill-discover.nu
use ../lib/vcs.nu
use ../lib/style.nu

# Format skill line with aligned columns
def format-skill [name: string, version: string, pad: int, warn?: string] {
    let name_pad = "" | fill -c ' ' -w ($pad - ($name | str length))
    let warning = if ($warn | is-empty) { "" } else { $" (style warn $warn)" }
    $"  ($name)($name_pad)($version)($warning)"
}

# Get xenix version from VERSION file
def xenix-version [] {
    try { open ($ROOT_DIR | path join "VERSION") | str trim } catch { "" }
}

# Compare versions (returns true if v1 < v2)
def version-lt [v1: string, v2: string] {
    let parse = {|v| $v | str replace "v" "" | split row "." | each { into int } }
    let a = do $parse $v1
    let b = do $parse $v2
    ($a.0 < $b.0) or ($a.0 == $b.0 and $a.1 < $b.1) or ($a.0 == $b.0 and $a.1 == $b.1 and $a.2 < $b.2)
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
        let current_ver = $ver
        $installed | each {|s|
            let warn = if ($s.system | is-not-empty) and ($current_ver | is-not-empty) and (version-lt $current_ver $s.system) {
                $"requires ($s.system)"
            } else { "" }
            print (format-skill $s.name (style dim $s.version) $pad $warn)
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
            print (format-skill $r.name (style dim $r.version) $avail_pad)
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
