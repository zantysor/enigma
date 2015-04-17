use lib '.';
use Enigma;

sub MAIN($setting='1M2C3K') {
  my @avail = $Enigma::Rotor::I, $Enigma::Rotor::II, $Enigma::Rotor::III;
  my @rotors = ();
  my $window = '';
  for $setting.comb -> $c {
    if '1' le $c le +@avail {
        push @rotors, @avail[$c-1];
    } elsif 'A' le uc($c) le 'Z' {
        $window ~= uc($c);
    }
  }
  my $m = Enigma::Machine.new;
  $m.rotors = @rotors if @rotors;
  $m.set_window($window);
  for $*IN.lines() -> $line {
    say $m.cipher($line);
  }
}
