#!/usr/bin/env nu
# description: Update plugins

use lib/plugin-config.nu *
use list.nu [get-installed]
use ../lib/style.nu
use ../lib/vcs.nu

# Update plugins
export def main [
    name?: string  # Plugin name (optional, updates all plugins if omitted)
    --system       # Also update system plugins
] {
    let installed = get-installed
    
    let to_update = if ($name | is-not-empty) {
        $installed | where name == $name
    } else if $system {
        $installed
    } else {
        $installed | where type == "plugin"
    }
    
    if ($to_update | is-empty) {
        print "Nothing to update"
        return
    }
    
    for p in $to_update {
        print $"Updating ($p.name)..."
        let dir = ($ROOT_DIR | path join $p.type $p.name)
        try {
            vcs update $dir
            print $"  (style ok 'Updated')"
        } catch {
            print $"  (style warn 'Failed to update')"
        }
    }
    
    # Run sync
    print "Syncing..."
    do { nu -c $"source ($ENV_FILE); plugin sync" } | complete | ignore
}
