# Skill discovery - single source of truth for finding installed skills

use skill-config.nu *
use ../../lib/md.nu

# Get version from VERSION file
def get-version [dir: string] {
    try { open ($dir | path join "VERSION") | str trim } catch { "" }
}

# Get metadata from SKILL.md if exists
def get-skill-meta [dir: string] {
    let skill_file = $dir | path join "SKILL.md"
    if ($skill_file | path exists) {
        let meta = (md parse $skill_file).meta
        {
            description: ($meta | get -o description | default "")
            system: ($meta | get -o system | default "")
        }
    } else {
        { description: "", system: "" }
    }
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
            let meta = get-skill-meta $dir
            {
                name: $name
                type: $type
                dir: $dir
                version: (get-version $dir)
                system: $meta.system
                has_mod: ($dir | path join "mod.nu" | path exists)
                description: $meta.description
                commands: (list-commands $dir)
            }
        }
    } | flatten
    | where { $in.has_mod }
}


