function fish_prompt --description Hydro
    set --local pyenv_or_uv (get_venv_info)
    echo -e "$_hydro_color_pwd$_hydro_pwd$hydro_color_normal $_hydro_color_git$$_hydro_git$hydro_color_normal$pyenv_or_uv $_hydro_color_duration$_hydro_cmd_duration$hydro_color_normal$_hydro_status$hydro_color_normal "
end

function get_venv_info
    # First try uv detection via VIRTUAL_ENV
    if test -n "$VIRTUAL_ENV"
        if string match -qr '.venv' "$VIRTUAL_ENV"
            set -l venv_name (basename "$VIRTUAL_ENV")  # ← gets ".venv" or custom name
            set -l python_version (python --version | string split ' ' | tail -n1)

            echo -n " ("
            set_color green
            echo -n "$VIRTUAL_ENV_PROMPT"
            set_color normal
            echo -n " - "
            set_color cyan
            echo -n "$python_version"
            set_color normal
            echo -n " - "
            set_color red
            echo -n "uv"
            set_color normal
            echo -n ")"
            return
        end
    end

    # Fallback to pyenv
    if type -q pyenv
        set -l pyenv_venv (pyenv version-name)
        if test "$pyenv_venv" != "system"
            set -l python_version (python --version | string split ' ' | tail -n1)
            echo -n " ("
            set_color green
            echo -n "$pyenv_venv"
            set_color normal
            echo -n " - "
            set_color cyan
            echo -n "$python_version"
            set_color normal
            echo -n " - "
            set_color red
            echo -n "pyenv"
            set_color normal
            echo -n ")"
        end
    end
end
