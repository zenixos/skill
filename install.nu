#!/usr/bin/env nu
# description: Install a plugin

use lib/plugin-config.nu *
use lib/plugin-discover.nu *
use ../lib/style.nu
use ../lib/vcs.nu

# Install a plugin
export def main [
    name: string  # Plugin name, optionally with @version (e.g. browser@v1.0.0)
] {
    let parts = ($name | split row "@")
    let plugin_name = $parts.0
    let version = $parts | get -o 1
    
    # Guard: system plugins
    if $plugin_name in $SYSTEM_PLUGINS {
        print $"(style err 'Error'): '($plugin_name)' is a system plugin, cannot install separately"
        return
    }
    
    # Guard: already installed
    let installed = get-installed | get name
    if $plugin_name in $installed {
        print $"(style err 'Error'): '($plugin_name)' is already installed"
        return
    }
    
    let target_dir = ($PLUGIN_DIR | path join $plugin_name)
    let repo = $"($GITHUB_ORG)/($plugin_name)"
    
    mkdir $PLUGIN_DIR
    
    print $"Installing ($plugin_name)..."
    try {
        if ($version | is-not-empty) {
            vcs clone $repo $target_dir --tag $version --track
        } else {
            vcs clone $repo $target_dir --track
        }
    } catch {|err|
        print $"(style err 'Error'): ($err.msg)"
        return
    }
    
    # Run sync
    print "Syncing..."
    do { nu -c $"source ($ENV_FILE); plugin sync" } | complete | ignore
    
    print $"(style ok 'Installed') ($plugin_name)"
}
