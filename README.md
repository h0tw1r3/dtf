# dtf

home directory management with git

## Quick Start

1. Create a public or private git repo and export `DTF_REPO` with the URL.

       export DTF_REPO="https://github.com/h0tw1r3/dtf_example.git"

2. Source the latest version of supported for your shell.
   _Currently only bash is supported._

       source /dev/stdin <<< "$(curl -Ls https://github.com/h0tw1r3/dtf/raw/main/.bash_dtf)"

3. Watch the magic! __Careful, files in your `DTF_REPO` will overwrite
   any existing files in your home directory!__

       dtf status
