# Raku-Woxi

An [Artistic-2.0](LICENSE) Raku package for invoking
[Woxi](https://github.com/ad-si/Woxi), the Rust implementation of a subset of
the Wolfram Language.

## Prerequisite: install Woxi

Woxi is a separate project and is not bundled with this package. Install its
`woxi` executable before using this module. Follow the installation directions
in the [Woxi README](https://github.com/ad-si/Woxi#installation); it documents
Cargo installation and prebuilt binaries.

## Installation

```sh
zef install Woxi
```

## Usage

```raku
use Woxi;

my $result = woxi-eval('Plus[1, 2]');
say (:$result);
say $result.stdout;

my $script = woxi-run($*CWD.add(<resources analysis.wls>));
say $script.stdout;
```

`woxi-eval`, `woxi-run`, and `woxi-version` return `Woxi::Result`, which
contains `.stdout`, `.stderr`, `.exitcode`, `.signal`, and `.source`.
Non-zero Woxi statuses remain inspectable; call `.throw-on-error` to raise
`Woxi::CommandFailed`. Use `:timeout(seconds)` and `:executable(path)` to
control execution. `woxi-available` checks whether an executable can respond
to `--version`.

The supported Wolfram Language subset is defined by Woxi itself; consult its
[README](https://github.com/ad-si/Woxi#features) and
[function-status list](https://github.com/ad-si/Woxi/blob/main/functions.csv).
