#!/usr/bin/env nu
# description: Install a plugin

use lib/plugin-config.nu *
use lib/plugin-discover.nu *
use ~/zenix_lib/style.nu

# Install a plugin
export def main [
    name: string  # Plugin name, optionally with @version (e.g. browser@v1.0.0)
] {
    let parts = ($name | split row "@")
    let plugin_name = $parts.0
    let version = $parts | get -o 1
    
    # Check if system plugin
    if $plugin_name in $SYSTEM_PLUGINS {
        print $"(style err 'Error'): '($plugin_name)' is a system plugin, cannot install separately"
        return
    }
    
    # Check if already installed
    let installed = get-installed | get name
    if $plugin_name in $installed {
        print $"(style err 'Error'): '($plugin_name)' is already installed"
        return
    }
    
    let target_dir = ($PLUGIN_DIR | path join $plugin_name)
    let repo_url = $"https://github.com/($GITHUB_ORG)/($plugin_name).git"
    
    # Create plugin directory if needed
    mkdir $PLUGIN_DIR
    
    # Clone with optional version
    print $"Installing ($plugin_name)..."
    let clone_args = if ($version | is-not-empty) {
        ["clone" "--branch" $version "--depth" "1" $repo_url $target_dir]
    } else {
        ["clone" $repo_url $target_dir]
    }
    
    let result = do { ^git ...$clone_args } | complete
    if $result.exit_code != 0 {
        print $"(style err 'Error'): Failed to clone ($repo_url)"
        print $result.stderr
        return
    }
    
    # Init jj
    print "Initializing jj..."
    cd $target_dir
    do { jj git init --colocate } | complete | ignore
    do { jj bookmark track main --remote=origin } | complete | ignore
    
    # Run sync
    print "Syncing..."
    do { nu -c $"source ($ENV_FILE); plugin sync" } | complete | ignore
    
    print $"(style ok 'Installed') ($plugin_name)"
}
