status is-interactive || exit

# Logging function that only prints when debug is enabled
function hydro_log --description "Simple logging function with debug level control"
    set --query hydro_log_level || set --global hydro_log_level "info"

    if test "$hydro_log_level" = "debug"
        echo $argv
    end
end

# Set default values for all color variables first
set --query hydro_color_pwd || set --global hydro_color_pwd $fish_color_normal
set --query hydro_color_git || set --global hydro_color_git $fish_color_normal
set --query hydro_color_error || set --global hydro_color_error $fish_color_error
set --query hydro_color_prompt || set --global hydro_color_prompt $fish_color_normal
set --query hydro_color_duration || set --global hydro_color_duration $fish_color_normal
set --query hydro_color_start || set --global hydro_color_start $fish_color_normal
set --query hydro_color_pyenv || set --global hydro_color_pyenv $fish_color_normal

set --global _hydro_git _hydro_git_$fish_pid
set --global _hydro_pyenv _hydro_pyenv_$fish_pid

function $_hydro_git --on-variable $_hydro_git
    commandline --function repaint
end

function $_hydro_pyenv --on-variable $_hydro_pyenv
    commandline --function repaint
end

function _hydro_pwd --on-variable PWD --on-variable hydro_ignored_git_paths --on-variable fish_prompt_pwd_dir_length
    set --local git_root (command git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
    set --local git_base (string replace --all --regex -- "^.*/" "" "$git_root")
    set --local path_sep /

    test "$fish_prompt_pwd_dir_length" = 0 && set path_sep

    if set --query git_root[1] && ! contains -- $git_root $hydro_ignored_git_paths
        set --erase _hydro_skip_git_prompt
    else
        set --global _hydro_skip_git_prompt
    end

    set --global _hydro_pwd (
        string replace --ignore-case -- ~ \~ $PWD |
        string replace -- "/$git_base/" /:/ |
        string replace --regex --all -- "(\.?[^/]{"(
            string replace --regex --all -- '^$' 1 "$fish_prompt_pwd_dir_length"
        )"})[^/]*/" "\$1$path_sep" |
        string replace -- : "$git_base" |
        string replace --regex -- '([^/]+)$' "\x1b[1m\$1\x1b[22m" |
        string replace --regex --all -- '(?!^/$)/|^$' "\x1b[2m/\x1b[22m"
    )
end

function _hydro_conda_auto --on-variable PWD
    status is-interactive; or return

    set -l current_dir $PWD
    set -l home_dir $HOME
    set -l python_version_file ".python-version"
    set -l found_version_file ""

    hydro_log "[DEBUG] Starting search for .python-version from '$current_dir' up to '$home_dir'"

    # Search for .python-version file from current directory up to home directory
    while true
        hydro_log "[DEBUG] Checking directory: '$current_dir' for .python-version file"

        if test -f "$current_dir/$python_version_file"
            set found_version_file "$current_dir/$python_version_file"
            hydro_log "[DEBUG] Found .python-version file: '$found_version_file'"
            break
        end

        # If we've reached the home directory or root, stop searching
        if test "$current_dir" = "$home_dir" -o "$current_dir" = "/"
            hydro_log "[DEBUG] Reached home directory or root, stopping search"
            break
        end

        # Move up one directory
        set current_dir (dirname "$current_dir")
        hydro_log "[DEBUG] Moving up to parent directory: '$current_dir'"
    end

    if test -n "$found_version_file"
        set -l req_env (string trim < "$found_version_file" | head -n1)
        hydro_log "[DEBUG] Using .python-version from '$found_version_file': '$req_env'"

        if string match -q "*/*" -- $req_env
            hydro_log "[DEBUG] Path contains '/', treating as conda env"
            set -l env_name (string split '/' $req_env)[-1]
            hydro_log "[DEBUG] Extracted env name: '$env_name'"
            hydro_log "[DEBUG] Current CONDA_DEFAULT_ENV: '$CONDA_DEFAULT_ENV'"

            if test "$CONDA_DEFAULT_ENV" != "$env_name" -a "$CONDA_DEFAULT_ENV" != "$req_env"
                hydro_log "[DEBUG] Activating conda env by name: '$env_name'"
                conda activate $env_name 2>/dev/null | source
                hydro_log "[DEBUG] After activation, CONDA_DEFAULT_ENV: '$CONDA_DEFAULT_ENV'"
            else
                hydro_log "[DEBUG] Already activated, skipping"
            end
        else
            hydro_log "[DEBUG] No '/' found, assuming regular pyenv env"
            # Switch to the specific pyenv version from the file
            if pyenv version | string match -q "$req_env"
                hydro_log "[DEBUG] Already using pyenv version: '$req_env', skipping"
            else
                hydro_log "[DEBUG] Switching to pyenv version: '$req_env'"
                pyenv local $req_env
                hydro_log "[DEBUG] Switched to pyenv version: '$(pyenv version)'"
            end
        end
    else
        hydro_log "[DEBUG] No .python-version file, switching to pyenv default"
        conda deactivate
        hydro_log "[DEBUG] Set to pyenv default version: '$(pyenv version)'"
    end
end

function _hydro_postexec --on-event fish_postexec
    set --local last_status $pipestatus
    set --global _hydro_status "$_hydro_newline$_hydro_color_prompt$hydro_symbol_prompt"

    for code in $last_status
        if test $code -ne 0
            set --global _hydro_status "$_hydro_color_error| "(echo $last_status)" $_hydro_newline$_hydro_color_prompt$_hydro_color_error$hydro_symbol_prompt"
            break
        end
    end

    test "$CMD_DURATION" -lt $hydro_cmd_duration_threshold && set _hydro_cmd_duration && return

    set --local secs (math --scale=1 $CMD_DURATION/1000 % 60)
    set --local mins (math --scale=0 $CMD_DURATION/60000 % 60)
    set --local hours (math --scale=0 $CMD_DURATION/3600000)

    set --local out

    test $hours -gt 0 && set --local --append out $hours"h"
    test $mins -gt 0 && set --local --append out $mins"m"
    test $secs -gt 0 && set --local --append out $secs"s"

    set --global _hydro_cmd_duration "$out "
end

function __hydro_prompt_git
    command kill $_hydro_last_pid 2>/dev/null

    set --query _hydro_skip_git_prompt && set $_hydro_git && return

    fish --private --command "
        set branch (
            command git symbolic-ref --short HEAD 2>/dev/null ||
            command git describe --tags --exact-match HEAD 2>/dev/null ||
            command git rev-parse --short HEAD 2>/dev/null |
                string replace --regex -- '(.+)' '@\$1'
        )

        test -z \"\$$_hydro_git\" && set --universal $_hydro_git \"\$branch \"

        command git diff-index --quiet HEAD 2>/dev/null
        test \$status -eq 1 ||
            count (command git ls-files --others --exclude-standard (command git rev-parse --show-toplevel)) >/dev/null && set info \"$hydro_symbol_git_dirty\"

        for fetch in $hydro_fetch false
            command git rev-list --count --left-right @{upstream}...@ 2>/dev/null |
                read behind ahead

            switch \"\$behind \$ahead\"
                case \" \" \"0 0\"
                case \"0 *\"
                    set upstream \" $hydro_symbol_git_ahead\$ahead\"
                case \"* 0\"
                    set upstream \" $hydro_symbol_git_behind\$behind\"
                case \*
                    set upstream \" $hydro_symbol_git_ahead\$ahead $hydro_symbol_git_behind\$behind\"
            end

            set --universal $_hydro_git \"\$branch\$info\$upstream \"

            test \$fetch = true && command git fetch --no-tags 2>/dev/null
        end
    " &

    set --global _hydro_last_pid $last_pid
end

function __hydro_prompt_pyenv
    # Async pyenv version detection
    command kill $_hydro_pyenv_last_pid 2>/dev/null
    fish --private --command "
        set pyenv_version (command pyenv version 2>/dev/null | string replace --regex -- ' .*' '')
        set python_version (python --version | string split ' ' --fields 2)
        if test -n \"\$pyenv_version\" && test \"\$pyenv_version\" != \"system\"
            set --universal $_hydro_pyenv \"(🐍 - \$pyenv_version - \$python_version)\"
        else
            set --universal $_hydro_pyenv \"\"
        end
    " &
    set --global _hydro_pyenv_last_pid $last_pid
end

function _hydro_prompt --on-event fish_prompt
    set --query _hydro_status || set --global _hydro_status "$_hydro_newline$_hydro_color_prompt$hydro_symbol_prompt"
    set --query _hydro_pwd || _hydro_pwd

    __hydro_prompt_git
    __hydro_prompt_pyenv
end

function _hydro_fish_exit --on-event fish_exit
    set --erase $_hydro_git
end

function _hydro_uninstall --on-event hydro_uninstall
    set --names |
        string replace --filter --regex -- "^(_?hydro_)" "set --erase \$1" |
        source
    functions --erase (functions --all | string match --entire --regex "^_?hydro_")
end

set --global hydro_color_normal (set_color normal)

for color in hydro_color_{pwd,git,error,prompt,duration,start,pyenv}
    function $color --on-variable $color --inherit-variable color
        set --query $color && set --global _$color (set_color $$color)
    end && $color
end

function hydro_multiline --on-variable hydro_multiline
    if test "$hydro_multiline" = true
        set --global _hydro_newline "\n"
    else
        set --global _hydro_newline ""
    end
end && hydro_multiline

set --query hydro_symbol_prompt || set --global hydro_symbol_prompt ❱
set --query hydro_symbol_git_dirty || set --global hydro_symbol_git_dirty •
set --query hydro_symbol_git_ahead || set --global hydro_symbol_git_ahead ↑
set --query hydro_symbol_git_behind || set --global hydro_symbol_git_behind ↓
set --query hydro_multiline || set --global hydro_multiline false
set --query hydro_cmd_duration_threshold || set --global hydro_cmd_duration_threshold 1000
