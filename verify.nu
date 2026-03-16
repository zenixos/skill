#!/usr/bin/env nu
# description: Verify skill commands are exported and documented

use lib/plugin-discover.nu
use ../lib/style.nu

def check-command [cmd_path: string, skill_name: string, scope: list] {
    let name = ($cmd_path | path basename | str replace ".nu" "")
    let found = ($scope | where name == $"($skill_name) ($name)")
    let exported = ($found | is-not-empty)
    let documented = $exported and (($found | first | get description) | is-not-empty)

    match [$documented $exported] {
        [true _] => { status: "ok", msg: "" }
        [false true] => { status: "warn", msg: "missing doc comment" }
        [false false] => { status: "error", msg: "not exported" }
    }
    | { name: $name, status: $in.status, msg: $in.msg }
}

def verify-skill [skill: record, scope: list] {
    $skill.commands | each {|cmd|
        let check = check-command $cmd $skill.name $scope
        let desc = match $check.status {
            "ok" => (style ok "ok")
            "error" => (style err "not exported")
            _ => (style warn ($check | get -o msg | default "warning"))
        }
        { category: $skill.name, name: $check.name, description: $desc }
    }
}

# Verify skill commands are exported and documented
export def main [] {
    let scope = scope commands | where type == 'custom' | select name description
    let skills = plugin-discover | where has_mod
    let data = $skills | each {|s| verify-skill $s $scope } | flatten
    style catalog $data
}
