function fish_prompt --description Hydro
    set --local pyenv (pyenv_prompt_info)
    echo -e "$_hydro_color_pwd$_hydro_pwd$hydro_color_normal $_hydro_color_git$$_hydro_git$hydro_color_normal$pyenv $_hydro_color_duration$_hydro_cmd_duration$hydro_color_normal$_hydro_status$hydro_color_normal "
end

function pyenv_prompt_info
    # Only show if pyenv is installed
    if not type -q pyenv
        return
    end

    set -l pyenv_venv (pyenv version-name)

    # Only show if not system Python
    if test "$pyenv_venv" != "system"
        set -l python_version (python --version | string split ' ' | tail -n1)
        set -l color_venv green
        set -l color_python cyan

        echo -n " "
        set_color normal
        echo -n "("
        set_color $color_venv
        echo -n "$pyenv_venv"
        set_color normal
        echo -n " - "
        set_color $color_python
        echo -n "$python_version"
        set_color normal
        echo -n ")"
    end
end
