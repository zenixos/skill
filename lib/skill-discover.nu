# Skill discovery - single source of truth for finding installed skills

use skill-config.nu *
use ../../lib/md.nu

# Get version from VERSION file
def get-version [dir: string] {
    try { open ($dir | path join "VERSION") | str trim } catch { "" }
}

# Get description from SKILL.md if exists
def get-description [dir: string] {
    let skill_file = $dir | path join "SKILL.md"
    if ($skill_file | path exists) {
        (md parse $skill_file).meta | get -o description | default ""
    } else { "" }
}

# List command files in a skill (excludes mod.nu)
def list-commands [dir: string] {
    glob $"($dir)/*.nu"
    | where {|f| ($f | path basename) != "mod.nu" }
    | sort
}

# List all installed skills with metadata
export def main [] {
    ["system", "plugin"] | each {|type|
        let dir = $ROOT_DIR | path join $type
        if not ($dir | path exists) { return [] }
        ls $dir
        | where type == "dir"
        | each {
            let dir = $in.name
            let name = $dir | path basename
            {
                name: $name
                type: $type
                dir: $dir
                version: (get-version $dir)
                has_mod: ($dir | path join "mod.nu" | path exists)
                description: (get-description $dir)
                commands: (list-commands $dir)
            }
        }
    } | flatten
    | where { $in.has_mod }
}


