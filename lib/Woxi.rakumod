unit module Woxi;

class Error is Exception is export { has Str $.detail is required; method message() { $!detail } }
class Unavailable is Error is export {
    has Str $.executable is required;
    method message() { "Cannot start Woxi executable '{$!executable}': {$.detail}" }
}
class Timeout is Error is export {
    has Real $.timeout is required;
    method message() { "Woxi did not finish within {$!timeout} seconds" }
}
class CommandFailed is Error is export {
    has Int $.exitcode is required;
    has Str $.stderr = '';
    method message() { "Woxi exited with status {$!exitcode}" ~ ($!stderr.trim.chars ?? ": {$!stderr.trim}" !! '') }
}

class Result is export {
    has Str $.stdout is required;
    has Str $.stderr is required;
    has Int $.exitcode is required;
    has Int $.signal is required;
    has Str $.source is required;
    method success(--> Bool:D) { $!exitcode == 0 && $!signal == 0 }
    method Str(--> Str:D) { $!stdout.trim-trailing }
    method throw-on-error(--> Woxi::Result:D) {
        unless self.success { CommandFailed.new(:detail('The Woxi command failed'), :$!exitcode, :$!stderr).throw }
        self
    }
}

sub executable-found(Str:D $executable --> Bool:D) {
    return $executable.IO.x if $executable.contains('/') || $executable.contains('\\');

    my @names = $executable;
    @names.append: $executable ~ '.exe', $executable ~ '.bat', $executable ~ '.cmd'
        if $*DISTRO.is-win;
    for (%*ENV<PATH> // '').split($*DISTRO.path-sep) -> $directory {
        for @names -> $name {
            return True if $directory.IO.add($name).x;
        }
    }
    False
}

sub run-woxi(@arguments, Str:D :$executable = 'woxi', Real :$timeout, Str:D :$source = '', --> Woxi::Result:D) {
    unless executable-found($executable) {
        Unavailable.new(:$executable, :detail('not found on PATH')).throw;
    }
    my $stdout = '';
    my $stderr = '';
    my $process = Proc::Async.new($executable, |@arguments);
    $process.stdout.tap(-> $text { $stdout ~= $text });
    $process.stderr.tap(-> $text { $stderr ~= $text });
    my $completion;
    try {
        $completion = $process.start;
        CATCH { default { Unavailable.new(:$executable, :detail(.message)).throw } }
    }
    if $timeout.defined {
        die Timeout.new(:detail('Timed out'), :$timeout) if $timeout <= 0;
        await Promise.anyof($completion, Promise.in($timeout));
        if $completion.status ~~ Planned {
            $process.kill;
            try {
                await $completion;
                CATCH { default { } }
            }
            Timeout.new(:detail('Timed out'), :$timeout).throw;
        }
    }
    my $result;
    try {
        $result = await $completion;
        CATCH { default { Unavailable.new(:$executable, :detail(.message)).throw } }
    }
    Woxi::Result.new(:$stdout, :$stderr, :exitcode($result.exitcode // 0), :signal($result.signal // 0), :$source)
}

sub woxi-eval(Str:D $code, Str:D :$executable = 'woxi', Real :$timeout, --> Woxi::Result:D) is export {
    run-woxi(['eval', $code], :$executable, :$timeout, :source($code))
}
sub evaluate(|c) is export { woxi-eval(|c) }
sub woxi-run(IO() $path, Str:D :$executable = 'woxi', Real :$timeout, --> Woxi::Result:D) is export {
    run-woxi(['run', $path.Str], :$executable, :$timeout, :source($path.Str))
}
sub woxi-version(Str:D :$executable = 'woxi', Real :$timeout --> Woxi::Result:D) is export {
    run-woxi(['--version'], :$executable, :$timeout)
}
sub woxi-available(Str:D :$executable = 'woxi', Real :$timeout = 5 --> Bool:D) is export {
    so try { woxi-version(:$executable, :$timeout).success }
}
