#!/usr/bin/env nu
# description: List installed and available plugins

use lib/plugin-config.nu *
use ../lib/vcs.nu

# Get installed plugins with version
export def get-installed [] {
    ["system", "plugin"] | each {|type|
        ls ($ROOT_DIR | path join $type)
        | where type == "dir"
        | each {
            let name = ($in.name | path basename)
            let dir = ($ROOT_DIR | path join $type $name)
            { name: $name, type: $type, version: (vcs version $dir) }
        }
    } | flatten
    | where { $in.version != "unknown" }
}

# Format output: installed first, system first, then by name
def format-output [] {
    sort-by name | sort-by type -r | sort-by status -r | select name status type version
}

# List all plugins
export def main [] {
    let installed = get-installed | each { $in | insert status "installed" }
    
    let available = vcs list-repos $GITHUB_ORG
    | where { $in.name not-in ($installed | get name) }
    | each { $in | insert type "plugin" | insert status "available" }
    
    $installed 
    | append $available
    | format-output
}
