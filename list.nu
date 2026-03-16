#!/usr/bin/env nu
# description: List installed and available plugins

use lib/plugin-config.nu *
use lib/plugin-discover.nu
use ../lib/vcs.nu
use ../lib/style.nu

def format-output [plugins: list, header: string, empty_msg: string] {
    print (style header $header)
    match ($plugins | is-empty) {
        true => { print $"  ($empty_msg)" }
        false => {
            let data = $plugins | each {|p|
                { 
                    category: (style category $p.type)
                    name: $p.name
                    description: (style dim ($p.version? | default ""))
                }
            }
            style catalog $data
        }
    }
}

# List all plugins
export def main [] {
    let installed = plugin-discover
    let installed_names = $installed | get name
    let exclude = ["zenix" "xenix" "system"]
    let available = vcs list-repos $GITHUB_ORG
        | where {|r| $r.name not-in $installed_names }
        | where {|r| $r.name not-in $exclude }
    
    format-output $installed "Installed" "(none)"
    print ""
    format-output $available "Available" "(all installed)"
}
