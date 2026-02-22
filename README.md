# dtf

home directory management with git

## Quick Start

1. Create a public or private git repo and export ` DTF_REPO ` with the URL.
   If you have an existing repo, you can use that, but make sure to backup any
   files in it before running [dtf] for the first time, as it will overwrite
   any existing files in the repo with the files in your home directory. If
   you don't have a repo.

       export DTF_REPO="<your public or private git repo url>"
       export DTF_BRANCH="main" # optional, defaults to "main"

2. Install the script by downloading and sourcing it:
   _Should work on any shell supporting [POSIX],
   but only tested on [ash], [bash] and [zsh]_

       curl -Ls https://github.com/h0tw1r3/dtf/raw/main/dtf.sh > ~/.dtf.sh
       . ~/.dtf.sh

   _The filename ~/.dtf.sh is important._

3. Watch the magic! __Careful, files in your ` DTF_REPO ` will overwrite
   any existing files in your home directory!__  

   First time [dtf] is run, it will clone the repo, checkout all the files,
   and update your shells "rc" file to make [dtf] available in future sessions.
   If you wish to skip the "rc" file update, you can set ` DTF_AUTORC ` to
   ` false ` before running the function.

       dtf status

[dtf]: https://github.com/h0tw1r3/dtf
[POSIX]: https://en.wikipedia.org/wiki/POSIX
[ash]: https://en.wikipedia.org/wiki/Almquist_shell
[bash]: https://en.wikipedia.org/wiki/Bash_(Unix_shell)
[zsh]: https://en.wikipedia.org/wiki/Z_shell
