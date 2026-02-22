# dtf

home directory management with git

## Quick Start

1. Create a public or private git repo and export `DTF_REPO` with the URL.

       export DTF_REPO="https://github.com/h0tw1r3/dtf_example.git"

2. Install the script by downloading and sourcing it:
   _Should work on any shell supporting POSIX,
   but only tested on ash, bash and zsh_

       curl -Ls https://github.com/h0tw1r3/dtf/raw/main/dtf.sh > ~/.dtf.sh
       . ~/.dtf.sh

3. Watch the magic! __Careful, files in your `DTF_REPO` will overwrite
   any existing files in your home directory!__

       dtf status
