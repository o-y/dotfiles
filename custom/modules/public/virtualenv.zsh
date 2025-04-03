###
### SETUP PYTHON ENVIRONMENT/TOOLS
###

# pyenv
if ! type pyenv &> /dev/null; then
    if [ -e "$HOME/.pyenv/bin" ]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init - zsh)"
    fi
fi

# miniconda
if [ -e "$HOME/miniforge3/bin/conda" ]; then
    eval "$($HOME/miniforge3/bin/conda shell.zsh hook)"
fi

# pixi
if [ -e "$HOME/.pixi/bin" ]; then
    export PATH="$PATH:$HOME/.pixi/bin"
fi
