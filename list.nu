#!/usr/bin/env nu
# description: List installed and available plugins

use lib/plugin-config.nu *
use lib/plugin-discover.nu
use ../lib/vcs.nu
use ../lib/style.nu

def print-installed [plugins: list] {
    print (style header "Installed")
    if ($plugins | is-empty) {
        print "  (none)"
    } else {
        let data = $plugins | each {|p|
            { 
                category: (style category $p.type)
                name: $p.name
                description: (style dim $p.version) 
            }
        }
        style catalog $data
    }
}

def print-available [plugins: list] {
    print (style header "Available")
    if ($plugins | is-empty) {
        print "  (all installed)"
    } else {
        $plugins | each {|p| print $"  ($p.name)" }
        null
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
    
    print-installed $installed
    print ""
    print-available $available
}
