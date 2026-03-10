export const SKILL_DIR = (path self | path dirname | path dirname)
export const ZENIX_DIR = ($SKILL_DIR | path dirname | path dirname)
export const PLUGIN_DIR = ($ZENIX_DIR | path join "plugin")
export const DATA_DIR = ($SKILL_DIR | path join "data")
export const ENV_FILE = ($ZENIX_DIR | path join "system/lib/env.nu")
export const GITHUB_ORG = "zenixos"
export const SYSTEM_PLUGINS = ["plugin" "agent" "watcher" "work"]
