# Ensures a pull_request block with [ main, develop ] exists in a workflow file.
# - If pull_request exists with [ main ], it upgrades to [ main, develop ].
# - If missing, inserts the block right after the first 'on:' line.
BEGIN { $/ = undef; }
my $f = <>;
if ($f =~ /^\s*pull_request:/m) {
  $f =~ s/(^\s*pull_request:\s*\n\s*branches:\s*)\[\s*main\s*\]/$1[ main, develop ]/m;
} else {
  $f =~ s/^on:\s*$/on:\n  pull_request:\n    branches: [ main, develop ]/m;
}
print $f;
