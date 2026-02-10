###
### SETUP PYTHON ENVIRONMENT/TOOLS
###

# pyenv [disused for now]
if ! type pyenv &> /dev/null; then
    if [ -e "$HOME/.pyenv/bin" ]; then
        export PATH="$PATH:$HOME/.pyenv/bin"
        eval "$(pyenv init - zsh)"
    fi
fi

# miniconda [disused for now]
if [ -e "$HOME/miniforge3/bin/conda" ]; then
    eval "$($HOME/miniforge3/bin/conda shell.zsh hook)"
fi

# # pixi
if [ -e "$HOME/.pixi/bin" ]; then
    export PATH="$PATH:$HOME/.pixi/bin"
fi
