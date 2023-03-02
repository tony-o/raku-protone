use Protone;

unit class Protone::Context;

has %!templates;
has %!spurts;
has %!context;

multi method compile(Str:D $name, Str:D :$code, Bool:D :$for-spurt = False) {
  if $for-spurt {
    %!spurts{$name}    = compile-str($name, :$code);
    %!templates{$name} = %!spurts{$name}.EVAL;
  } else {
    %!templates{$name} = compile(:$code);
  }
}

multi method compile(Str:D $name, Str:D :$path, Bool:D :$for-spurt = False) {
  if $for-spurt {
    %!spurts{$name}    = compile-str($name, :$path);
    %!templates{$name} = %!spurts{$name}.EVAL;
  } else {
    %!templates{$name} = compile(:$path);
  }
}

multi method available(--> List) {
  %!templates.keys;
}

method run(Str:D $name, *%values) {
  die "$name requested is not found, available: {%!templates.keys.join(", ")}"
    unless %!templates{$name}:exists;
  %!templates{$name}(|%!context, |%values);
}

method register(Str:D $name, Callable:D $fn) {
  %!context{$name} = $fn;
}

method set-debug(Bool:D $b) {
  $Protone::DEBUG = $b;
}
