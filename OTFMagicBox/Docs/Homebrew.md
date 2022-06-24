# Homebrew Installation

Homebrew requires macOS 10.15 or higher, while versions 10.10–10.14 are supported on a best-effort basis.

The one-liner installation method found on the [Homebrew](https://brew.sh/) main page:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

requires the *Bourne-again shell*, i.e., bash.

Note that zsh, fish, tcsh and csh **will not work**. (Without bash, you may get a non-descriptive error such as ”Illegal variable name.”)

So switch to `/bin/bash` (in System Preferences --> Users & Groups --> Right click on your username (must be admin) --> Advanced Options... or in the Terminal preferences) for the command above to succeed.


