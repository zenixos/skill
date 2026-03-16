#!/usr/bin/env nu
# description: Update skills

use lib/skill-config.nu *
use lib/skill-discover.nu
use sync.nu
use ../lib/style.nu
use ../lib/vcs.nu

# Update skills
export def main [
    ...names: string  # Skill names (updates all if omitted)
    --system          # Also update system skills
] {
    let installed = skill-discover
    let to_update = if ($names | is-empty) {
        $installed | where { $system or $in.type == "plugin" }
    } else {
        $installed | where { $in.name in $names }
    }
    
    $to_update | each {|s|
        vcs update $s.dir --track=$PROJECT.track
        print $"(style ok 'Updated') ($s.name)"
    }
    
    sync
}
