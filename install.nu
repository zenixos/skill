#!/usr/bin/env nu
# description: Install a skill

use lib/skill-config.nu *
use lib/skill-discover.nu
use sync.nu
use ../lib/style.nu
use ../lib/vcs.nu

# Install a single skill
def install-one [name: string] {
    let parts = $name | split row "@"
    let skill_name = $parts.0
    let version = $parts | get -o 1 | default ""
    
    if $skill_name in (skill-discover | get name) {
        print $"(style err 'Error'): '($skill_name)' is already installed"
        return
    }
    
    let repo = $"($GITHUB_ORG)/($skill_name)"
    let is_core = $skill_name in $CORE_SKILLS
    let target_dir = if $is_core { $ROOT_DIR | path join "system" } else { $PLUGIN_DIR }
    let dir = $target_dir | path join $skill_name
    
    vcs clone $repo $dir --tag $version
    vcs init $dir --track=$PROJECT.track
    print $"(style ok 'Installed') ($skill_name)"
}

# Install skills
export def main [
    ...names: string  # Skill names, optionally with @version (e.g. browser@v1.0.0)
] {
    $names | each {|name| install-one $name }
    sync
}
