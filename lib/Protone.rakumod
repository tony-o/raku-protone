unit module Protone;

our $OPEN  = '{{';
our $CLOSE = '}}';
our $DEBUG = False;

sub esc(Str:D $text) {
  S:g/\r/'~"\\r"~'/ given (S:g/\n/'~"\\n"~'/ given (S:g/\'/\\'/ given $text));
}

multi sub compile(Str:D $name = "p{DateTime.now.posix}", Str:D :$code --> Callable) is export {
  compile-str($name, :$code).EVAL;
}

multi sub compile(Str:D $name = "p{DateTime.now.posix}", Str:D :$path --> Callable) is export {
  die "$path does not exist or is not a readable file"
    unless $path.IO.e && $path.IO.f;
  compile($name, code => $path.slurp);
}

multi sub compile-str(Str:D $name = "p{DateTime.now.posix}", Str:D :$path --> Str) is export {
  die "$path does not exist or is not a readable file"
    unless $path.IO.e && $path.IO.f;
  compile-str($name, code => $path.slurp);
}

multi sub compile-str(Str:D $name = "p{DateTime.now.posix}", Str:D :$code --> Str) is export {
  my uint64 $idx   = 0;
  my Str $opener   = $OPEN//'{{';
  my int $openlen  = $opener.chars;
  my Str $closer   = $CLOSE//'}}';
  my int $closelen = $closer.chars;
  my int $srclen   = $code.chars;
  my str $out      = "sub $name\(*%ctx --> Str) \{\n  my \$out = '';\n";
  my str $tmp;
  my int $cidx     = 0;
  while $idx < $srclen {
    if $code.substr($idx, $openlen) eq $opener {
      $out ~= "  \$out ~= '{esc($code.substr($cidx, $idx))}';\n"
        unless $idx == 0;
      $idx += $openlen;
      $cidx = $idx;
      while $idx + $closelen <= $srclen && $code.substr($idx, $closelen) ne $closer {
        $idx++;
      }
      die "Unmatched opening bracket @ $cidx\n  -HERE-> '{$code.substr($cidx-$openlen, 15)}'" if $idx >= $srclen;
      $tmp = $code.substr($cidx, $idx - $cidx);
      if $tmp ~~ m/^ <+alnum>+ $/ {
        $out ~= "  \$out ~= \%ctx\{'{$tmp}'\}//'';\n";
      } else {
        $tmp ~~ s:g/ <?after ^|<+[ \r\n\t{}()\.]>> (<+alnum>+) <?before <+[ \r\n\t(){}\.]>|$> /\%ctx<$0>/;
        $out ~= "  \$out ~= $tmp // '';\n";
      }
      $idx += $closelen;
      $cidx = $idx;
    }
    $idx++;
  }
  $out ~= "  \$out ~= '{esc($code.substr($cidx, $idx))}';\n"
    unless $cidx >= $srclen;
  $out ~= "  \$out;\n";
  $out ~= "}\n";
  $*ERR.say($out) if $DEBUG;
  $out;
}
