module Enigma;

class Plugboard {
  has $.wires;
  method exchange($letter) {
    if defined(my $i = $.wires.index($letter)) {
      return $.wires.comb[ Int($i/2) + 1 - $i%2 ];
    } else {
      return $letter;
    }
  }
}

$Plugboard::Zero = Plugboard.new(wires => '');

class Reflector {
  has $.wires;

  method reflect($letter) {
    return if 'A' gt uc($letter) || uc($letter) gt 'Z';
    return $.wires.comb[$letter.ord - 'A'.ord];
  }
}

$Reflector::B = Reflector.new( wires => 'YRUHQSLDPXNGOKMIEBFZCWVJAT' );
$Reflector::C = Reflector.new( wires => 'FVPJIAOYEDRZXWGCTKUQSBNMHL' );

class Rotor {
  has $.wires;
  has $.notch;

  method left_to_right($letter, $position=0) {
    my $row = ($letter.ord - 'A'.ord + $position) % $.wires.chars;
    my $key = ('A'.ord + $row).chr;
    return (($.wires.index($key) - $position) % $.wires.chars + 'A'.ord).chr;
  }

  method right_to_left($letter, $position=0) {
    my $row = ($letter.ord - 'A'.ord + $position) % $.wires.chars;
    my $key = $.wires.comb[$row];
    return (($key.ord - 'A'.ord - $position) % $.wires.chars + 'A'.ord).chr;
  }
}

$Rotor::I   = Rotor.new(wires => 'EKMFLGDQVZNTOWYHXUSPAIBRCJ', notch => 'Q');
$Rotor::II  = Rotor.new(wires => 'AJDKSIRUXBLHWTMCQGZNPYFVOE', notch => 'E');
$Rotor::III = Rotor.new(wires => 'BDFHJLCPRTXVZNYEIWGAKMUSQO', notch => 'V');
$Rotor::IV  = Rotor.new(wires => 'ESOVPZJAYQUIRHXLNFTGKDCMWB', notch => 'J');
$Rotor::V   = Rotor.new(wires => 'VZBRGITYUPSDNHLXAWMJQOFECK', notch => 'Z');

class Mount {
  has $.rotor;
  has $.position is rw = 0;
  has $!notch_pos;

  submethod BUILD(:$!rotor) {
    $!notch_pos = $!rotor.notch.ord - 'A'.ord;
  }

  method set_window($letter) {
      if 'A' le $letter le 'Z' {
          $.position = $letter.ord - 'A'.ord;
      }
  }

  method rotate {
    my $carry = $.position == $!notch_pos;
    $.position = ($.position + 1) % $.rotor.wires.chars;
    return $carry;
  }

  method left_to_right($letter) {
    return $.rotor.left_to_right($letter, $.position);
  }

  method right_to_left($letter) {
    return $.rotor.right_to_left($letter, $.position);
  }
}

class Machine {
  has $!mounts;
  has $.reflector = $Reflector::B;
  has $.plugboard = $Plugboard::Zero;

  submethod BUILD(:$rotors = [ $Rotor::I, $Rotor::II, $Rotor::III ]) {
    self.mount($rotors);
  }

  method mount($rotors) {
    $!mounts = $rotors.map(-> $rotor {Mount.new(rotor => $rotor)});
  }

  method set_window($str) {
    for $str.comb.kv -> $i, $letter {
      return if 'A' gt uc($letter) || uc($letter) gt 'Z';
      $!mounts[$i].set_window(uc $letter);
    }
  }

  method cipher($text) {
    return $text.comb.map( -> $letter {
      my $l = uc $letter;
      if 'A' gt $l || $l gt 'Z' {
        $letter;
      } else  {
        my ($left, $mid, $right) = @($!mounts);

        my $advance = True;
        for $right, $mid, $left -> $r {
          $advance = $r.rotate if $advance;
        }

        $.plugboard.exchange(
         $right.left_to_right(
          $mid.left_to_right(
           $left.left_to_right(
            $.reflector.reflect(
           $left.right_to_left(
          $mid.right_to_left(
         $right.right_to_left(
        $.plugboard.exchange($l)))))))))
      }
    }).join
  }
}
