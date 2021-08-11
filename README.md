# CVM

Composer Version Manager - A script to manage multiple versions of Composer the easy way.

### Compatibility

Developed and tested on macOS, should work on most Linux distributions, probably not functional on Windows.

### Install

To install, clone the repository:

```sh
git clone git@github.com:mitchellnemitz/cvm.git "$HOME/.cvm"
```

Then update your `~/.bash_profile`, `~/.zshrc`, or shell equivalent:

```sh
if [ -f "$HOME/.cvm/cvm.sh" ]; then
    export CVM_DIR="$HOME/.cvm"
    source "$CVM_DIR/cvm.sh"
fi
```

Lastly, start a new shell, or source your updated shell config file:

```sh
# Bash
source "$HOME/.bash_profile"

# ZSH
source "$HOME/.zshrc"
```

### Update

To update, pull the latest changes from master

```sh
cd "$HOME/.cvm"
git fetch origin master
git pull origin/master
```

### Usage

Run `cvm --help` for a summary of commands.

To install a new version of composer:

```sh
# by exact version
$ cvm install 1.20.22
$ cvm install 2.1.5

# by major version alias
$ cvm install 1.x
$ cvm install 2.x

# by stability alias
$ cvm install stable
$ cvm install preview
$ cvm install snapshot
```

To see installed versions of composer (arrows indicate exact versions for aliases):

```sh
$ cvm list
1.10.22
2.1.5
1.x -> 1.10.22
2.x -> 2.1.5
```

To use an installed version of composer:

```sh
# by exact version
$ cvm use 2.1.5
Using Composer version 2.1.5 1970-01-01 00:00:00

# by major version
$ cvm use 2.x
Using Composer version 2.1.5 1970-01-01 00:00:00
```

To switch back to the system version of composer:

```sh
$ cvm use system
```

To update the version of composer used by an alias:

```sh
$ cvm update 1.x
Updating Composer version 1.x
Using Composer version 1.10.22 1970-01-01 00:00:00
```

To remove an installed version of composer:

```sh
# by exact version (also removes related aliases)
$ cvm remove 1.10.22
Removed Composer version 1.10.22

# by alias (exact version remains installed)
$ cvm remove 2.x
Removed Composer version 2.x
```

### .cvmrc

If you don't pass a version to cvm, it will attempt to locate a `.cvmrc` file in the current directory and treat the contents as the intended version instead. This is a convenient way to explicitly declare are share your composer version for a given project.

The simplest way to generate a `.cvmrc` for your project is to echo the chosen version and redirect the output to a file:

```sh
echo "1.x" > .cvmrc
```

Now whenever you open your project, run `cvm use` and the version declared in your `.cvmrc` file will be selected. If the correct version of composer isn't installed, run `cvm install` instead.

### Development

Install the script as normal, make changes to `$HOME/.cvm/cvm.sh`, and run `cvm --reload` before testing.

### Support

Bugs should be reported via [Github Issues](https://github.com/mitchellnemitz/cvm/issues/new).

Feature requests are welcome, pull requests are preferred, but in all things please remember the human.
