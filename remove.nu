#!/usr/bin/env nu
# description: Remove a skill

use lib/skill-config.nu *
use lib/skill-discover.nu
use sync.nu
use ../lib/style.nu

# Remove a single skill
def remove-one [name: string, installed: list] {
    if $name == "skill" {
        print $"(style err 'Error'): cannot remove 'skill' itself"
        return
    }
    
    let skill = $installed | where name == $name | first | default null
    
    if $skill == null {
        print $"(style err 'Error'): '($name)' is not installed"
        return
    }
    
    rm -rf $skill.dir
    print $"(style ok 'Removed') ($name)"
}

# Remove skills
export def main [
    ...names: string  # Skill names
] {
    let installed = skill-discover
    $names | each {|name| remove-one $name $installed }
    sync
}
