# dtf

home directory management with git

## Quick Start

1. (Optional) Create a public or private git repo and export ` DTF_REPO ` with
   the URL. If you have an existing repo, you can use that, but make sure to
   backup any files in it before running [dtf] for the first time, as it will
   overwrite any existing files in the repo with the files in your home
   directory. If you don't have a repo yet, you can run [dtf] without
   ` DTF_REPO ` for a local-only setup and add a remote later with
   ` dtf remote add origin <url> `.

       export DTF_REPO="<your public or private git repo url>"

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

## Configuration

- **DTF_REPO** — Optional. Used only on first init when no origin remote
  exists. If unset, [dtf] initializes a local-only repo; add a remote later
  with ` dtf remote add origin <url> `.
- **DTF_BRANCH** — Optional override for branch selection. If unset, [dtf]
  auto-detects: tries ` main ` and ` master `, or prompts interactively when
  multiple branches exist.
- **DTF_AUTORC** — Set to ` 0 ` or ` false ` to skip automatic rc file setup.

When ` DTF_REPO ` is set but the remote is unreachable (network, auth, 404,
etc.), [dtf] removes the failed remote and continues with a local-only repo
instead of exiting.

[dtf]: https://github.com/h0tw1r3/dtf
[POSIX]: https://en.wikipedia.org/wiki/POSIX
[ash]: https://en.wikipedia.org/wiki/Almquist_shell
[bash]: https://en.wikipedia.org/wiki/Bash_(Unix_shell)
[zsh]: https://en.wikipedia.org/wiki/Z_shell
