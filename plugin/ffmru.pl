#!/usr/bin/perl -w
# WHAT: search ~/.vim_mru_files
# GPL(C) moshahmed at gmail
use strict;
use Cwd;
use Time::Piece;

my $cmd = $0 =~ s,.*[/\\],,r;
my $today=localtime->strftime('%Y-%m-%d_%H%M');
# @mrufilelist is sorted by time by vim
my (@mrufilelist, %seen, %grep_seen);
my ($verbose, $quickfix, $skipre);
my ($filere, $wordre);
my ($cdonly, %printed_dir, $asc);
my $GITE = $ENV{GITE} || '';
my( $HOME )= $ENV{HOME};
my $PWD  = getcwd();
my( $WINDIR ) = $ENV{'WINDIR'};
my %baddir;

# see ~/mcolor/xcolors2.pl for color sequences.
my ($color_red, $color_blue, $color_reset)=("\e[1;31m", "\e[1;34m", "\e[0m");

for ($HOME, $PWD, $WINDIR){
  s,\\,/,g; s,/cygdrive/(\w)/,$1:/,;
}

my @mru_files = (
    "${HOME}/.vim_mru_files",
    # "${HOME}/.viminfo"
);

my $USAGE="
USAGE: $cmd [OPTIONS] FILERE [WORDRE] .. Print matching files/lines in ~/.vim_mru_files
  eg. $cmd mpy activate                  .. search activate in mru files matching mpy
    Output is sorted by time asc, so latest MRU is last.
Options:
  -s/SKIPRE .. skip files matching SKIPRE
  -q        .. quickfix output matching path:1:1 for piping to vim -q -
  -n        .. no color, autoset if output is piped. 
  -cd filere .. print dir of MRU/*filere*
  -cd filere WORDRE  .. search wordre in all files in dirs of MRU files,
                ie. grep wordre glob((dirname MRU/filere)/*)
  -asc      .. asc time sort results, so newest is last.
  -gite=dir .. abbrev env GITE=gitrepo in output.
  -v,-h     .. verbose, help
Notes:
  . All regex are perlre icase.
  . Files are only searched once, even if duplicated in MRU
";

# no colors if pipe
unshift(@ARGV,qw( -n )) if ! -t STDOUT;

while( $_ = $ARGV[0], defined($_) && /^-/ ){
    shift; m/^--$/ && last;
    if(     m/^-v$/        ){ $verbose++;
    }elsif( m/^-q$/        ){ $quickfix=1; # unshift(@ARGV,qw( -n )); # -n for no colors
    }elsif( m/^-n$/        ){ ($color_red,$color_blue,$color_reset)=('','','');
    }elsif( m,^-s/(.+)$,   ){ $skipre=$1;
    }elsif( m/^-cd$/        ){ $cdonly=1;
    }elsif( m/^-asc$/        ){ $asc=1;
    }elsif( m/^-gite=(.+)$/  ){ $GITE=$1;
    }elsif( m/^-[?h]$/       ){ die $USAGE;
    }else{ die $USAGE."Invalid option '$_'\n";
    }
}

$filere = shift or die $USAGE;
$wordre = shift;

foreach my $file (@mru_files) {
  process_mru($file);
}

# End of main

sub grep_file {
  my ($file, $abfile, $filere, $wordre, $filetime) = @_;
  $file =~ s,\\,/,g;
  return if $grep_seen{$file}++; # grep only once
  open(my $fh, $file) or warn "Cannot read $file";
  while (my $line = <$fh>) {
    chomp $line;
    next unless $line =~ s/$wordre/${color_red}$&${color_reset}/gio;
    if ($quickfix){
      printf "%s:%d:%s %s\n", $abfile, $., $line, $filetime;
    }else{
      printf "%s%s:%d:%s\n", $filetime, $abfile, $., $line;
    }
  }
  close $fh;
}

sub abbrev_file {
  my $file = shift;
  # order is important
  $file =~ s,^$PWD/,./,io;
  $file =~ s,^$GITE/,\$GITE/,io if $GITE;
  $file =~ s,^$HOME/,~/,io;
  return $file;
}

sub unabbrev_file {
  my $file = shift;
  for ($file) {
    s,\\,/,g;
    s,[~]/,$HOME/,;
    s,\$SRC/,$ENV{SRC}/,;
    s,/cygdrive/(\w)/,$1:/,;
    # mosh_mru_abbrev_dict in ~/mvim/lib/mru.vim
    warn "Unexpanded envvar in $_\n" if m/\$/;
  }
  return $file;
}

sub process_mru {
  my $vim_mru_file = shift;
  if (! -f $vim_mru_file ){
    warn "Cannot find vim_mru_file $vim_mru_file";
    return;
  }

  my $filename = $vim_mru_file;
  open(D,$filename ) or die "cannot read $filename \n";
  warn "# Reading $filename on $today\n" if $verbose;
  my $count=0;
  my @lines = <D>;
  if ($asc) {
    @lines = reverse @lines;
  }
  # LINE: while(<D>) 
  LINE: foreach (@lines) {
    my $path = $_;
    chomp $path;
    $path =~ s,\\,/,g;

    if ( m/PWD=/ ) { # dated ~/.vim_mru_files
      ($path) = split( qq/\t/, $path, 2); # keep only the first column
    }elsif( m/^>\s+(\S+)/ ) { # ~/.viminfo marks
      $path = $1;
    }elsif( m/^'M\s\d+\s\d+\s+(\S+)/ ) { # ~/.viminfo file marks
      $path = $1;
    }elsif( m/^-'\s\d+\d+(\S+)/ ) { # ~/.viminfo jumplist
      $path = $1;
    }
    if ($path =~ m,^(\w):, ){  # path has drive letter?
      my $drive = $1;
      next LINE if $baddir{$drive};
      if (! -d "$drive:/" ){
        warn "# missing $drive:/\n" if $verbose;
        $baddir{$drive}++;
        next LINE;
      }
    }

    my $filetime='';
    if ( m/\s(\d\d\d\d-\w+-\d+)/ ) {
      $filetime = $1." ";
    }

    # Got a path.
    my $abfile = $path;
    $path = unabbrev_file($path);

    $abfile = abbrev_file($abfile);

    # color the match
    $abfile =~ s,($filere),${color_blue}$1${color_reset},gio;

    # Filter the path
    next LINE if     $seen{$path}++;
    next LINE unless $path =~ m/$filere/gio;
    next LINE if     $skipre && $path =~ m/$skipre/gio;
    $count++;

    if( $cdonly ) {
      my $cddir = $path; $cddir =~ s,/[^/]*$,,; # dirname
      next LINE if $printed_dir{$cddir}++;
      next LINE unless -d $cddir;
      for( $abfile ){
        s,/[^/]*$,,; # dirname
        s,^~,%HOME%, if $WINDIR; # s,^~,$HOME,;
      }
      if ($wordre) { # grep $wordre all files in $cddir/*.*
        my @cdfiles = sort(glob("$cddir/*"));
        for $path (@cdfiles) {
          next unless -T $path;
          grep_file($path, $path, '.', $wordre, $filetime);
        }
      }else{
        # my $basename = $path ; $basename =~ s,^.*/,,;
        printf "cd %s\n", $abfile;
      }
      next LINE;
    }  
    next unless -f $path;
    next unless -T $path;

    # Search the path
    if ($wordre) {
      grep_file($path, $abfile, $filere, $wordre, $filetime);
      next LINE;
    }
    if( $quickfix ) {
      printf "%s:1:1\n", $abfile;
      next LINE;
    }
    printf "%s%s\n", $filetime, $abfile;
  }
  printf STDERR "# Found %d files in %s\n", $count, $filename 
    if $verbose;
  if ($count == 0 && not $wordre) {
    printf STDERR "# No matches for filere=/$filere/, Usage: $cmd filere [wordre]";
  }
}
