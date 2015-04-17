module Enigma;

class Reflector {
  has $.wires;
  has $.position is rw = 0;

  method reflect($letter) {
    return if 'A' gt uc($letter) || uc($letter) gt 'Z';
    return $.wires.comb[$.position + $letter.ord - 'A'.ord];
  }
}

$Reflector::B = Reflector.new( wires => "YRUHQSLDPXNGOKMIEBFZCWVJAT" );
$Reflector::C = Reflector.new( wires => "FVPJIAOYEDRZXWGCTKUQSBNMHL" );

class Rotor is Reflector {
  has $.notch;
  has $!notch_pos;

  submethod BUILD(:$!notch) {
    $!notch_pos = $!notch.ord - 'A'.ord;
  }

  method set_window($letter) {
      if 'A' le $letter le 'Z' {
          $.position = $letter.ord - 'A'.ord;
      }
  }

  method rotate {
    my $carry = $.position == $!notch_pos;
    $.position = ($.position + 1) % $.wires.chars;
    return $carry;
  }

  method left_to_right($letter) {
    my $row = ($letter.ord - 'A'.ord + $.position) % $.wires.chars;
    my $key = ('A'.ord + $row).chr;
    return (($.wires.index($key) - $.position) % $.wires.chars + 'A'.ord).chr;
  }

  method right_to_left($letter) {
    my $row = ($letter.ord - 'A'.ord + $.position) % $.wires.chars;
    my $key = $.wires.comb[$row];
    return (($key.ord - 'A'.ord - $.position) % $.wires.chars + 'A'.ord).chr;
  }
}

$Rotor::I   = Rotor.new(wires => 'EKMFLGDQVZNTOWYHXUSPAIBRCJ', notch => 'Q');
$Rotor::II  = Rotor.new(wires => "AJDKSIRUXBLHWTMCQGZNPYFVOE", notch => "E");
$Rotor::III = Rotor.new(wires => "BDFHJLCPRTXVZNYEIWGAKMUSQO", notch => "V");
$Rotor::IV  = Rotor.new(wires => "ESOVPZJAYQUIRHXLNFTGKDCMWB", notch => "J");
$Rotor::V   = Rotor.new(wires => "VZBRGITYUPSDNHLXAWMJQOFECK", notch => "Z");

class Machine {
  has $.rotors is rw = [ $Rotor::I, $Rotor::II, $Rotor::III ];
  has $.reflector = $Reflector::B;

  method set_window($str) {
    for $str.comb.kv -> $i, $letter {
      return if 'A' gt uc($letter) || uc($letter) gt 'Z';
      $.rotors[$i].set_window(uc $letter);
    }
  }

  method cipher($text) {
    return $text.comb.map( -> $letter {
      my $l = uc $letter;
      if 'A' gt $l || $l gt 'Z' {
        $letter;
      } else  {
        my ($left, $mid, $right) = @($.rotors);

        my $advance = True;
        for $right, $mid, $left -> $r {
          $advance = $r.rotate if $advance;
        }

        $right.left_to_right(
          $mid.left_to_right(
           $left.left_to_right(
            $.reflector.reflect(
           $left.right_to_left(
          $mid.right_to_left(
         $right.right_to_left(
        $l))))))) 
      }
    }).join
  }
}
