#!/usr/bin/env nu
# description: Remove a skill

use lib/skill-config.nu *
use lib/skill-discover.nu
use sync.nu
use ../lib/style.nu

# Remove a skill
export def main [
    name: string  # Skill name
] {
    let skill = skill-discover | where name == $name | first | default null
    
    if $skill == null {
        print $"(style err 'Error'): '($name)' is not installed"
        return
    }
    
    if $skill.type == "system" {
        print $"(style err 'Error'): cannot remove system skill '($name)'"
        return
    }
    
    cd $ROOT_DIR
    rm -rf $skill.dir
    sync
    print $"(style ok 'Removed') ($name)"
}
