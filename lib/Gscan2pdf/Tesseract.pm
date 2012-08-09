package Gscan2pdf::Tesseract;

use 5.008005;
use strict;
use warnings;
use Carp;
use File::Temp;    # To create temporary files
use File::Basename;
use Gscan2pdf::Document;    # for slurp

my ( %languages, $installed, $setup, $version, $tessdata, $datasuffix,
 $logger );

sub setup {
 ( my $class, $logger ) = @_;
 return $installed if $setup;

 my ( $exe, undef ) = Gscan2pdf::Document::open_three('which tesseract');
 if ( defined $exe ) {
  $installed = 1;
 }
 else {
  return;
 }
 my ( $out, undef ) = Gscan2pdf::Document::open_three("tesseract '' '' -l ''");
 ( $tessdata, $version, $datasuffix ) = parse_tessdata($out);

 unless ( defined $tessdata ) {
  if ( defined($version) and $version > 3.01 ) {
   my ( $lib, undef ) = Gscan2pdf::Document::open_three("ldd $exe");
   if ( $lib =~ /libtesseract\.so.\d+\ =>\ ([\/a-zA-Z0-9\-\.\_]+)\ /x ) {
    ( $out, undef ) = Gscan2pdf::Document::open_three("strings $1");
    $tessdata = parse_strings($out);
   }
   else {
    return;
   }
  }
  else {
   return;
  }
 }

 $logger->info("Found tesseract version $version. Using tessdata at $tessdata");
 $setup = 1;
 return $installed;
}

sub parse_tessdata {
 my @output = @_;
 my $output = join ",", @output;
 my ( $v, $suffix );
 if ( $output =~ /\ v(\d\.\d\d)\ /x ) {
  $v = $1 + 0;
 }
 while ( $output =~ /\n/x ) {
  $output =~ s/\n.*$//gx;
 }
 if ( $output =~ s/^Unable\ to\ load\ unicharset\ file\ //x ) {
  $v = 2 unless defined $v;
  $suffix = '.unicharset';
 }
 elsif ( $output =~ s/^Error\ openn?ing\ data\ file\ //x ) {
  $v = 3 unless defined $v;
  $suffix = '.traineddata';
 }
 elsif ( defined($v) and $v > 3.01 ) {
  return ( undef, $v, '.traineddata' );
 }
 else {
  return;
 }
 $output =~ s/\/ $suffix $//x;
 return $output, $v, $suffix;
}

sub parse_strings {
 my ($strings) = @_;
 my @strings = split "\n", $strings;
 for (@strings) {
  return $_ . "tessdata" if (/\/ share \//x);
 }
 return;
}

sub languages {
 unless (%languages) {
  my %iso639 = (
   ara        => 'Arabic',
   bul        => 'Bulgarian',
   cat        => 'Catalan',
   ces        => 'Czech',
   chr        => 'Cherokee',
   chi_tra    => 'Chinese (Traditional)',
   chi_sim    => 'Chinese (Simplified)',
   dan        => 'Danish',
   'dan-frak' => 'Danish (Fraktur)',
   deu        => 'German',
   'deu-f'    => 'German (Fraktur)',
   'deu-frak' => 'German (Fraktur)',
   ell        => 'Greek',
   eng        => 'English',
   fin        => 'Finish',
   fra        => 'French',
   heb        => 'Hebrew',
   hin        => 'Hindi',
   hun        => 'Hungarian',
   ind        => 'Indonesian',
   ita        => 'Italian',
   jpn        => 'Japanese',
   kor        => 'Korean',
   lav        => 'Latvian',
   lit        => 'Lituanian',
   nld        => 'Dutch',
   nor        => 'Norwegian',
   pol        => 'Polish',
   por        => 'Portuguese',
   que        => 'Quechua',
   ron        => 'Romanian',
   rus        => 'Russian',
   slk        => 'Slovak',
   'slk-frak' => 'Slovak (Fraktur)',
   slv        => 'Slovenian',
   spa        => 'Spanish',
   srp        => 'Serbian (Latin)',
   swe        => 'Swedish',
   'swe-frak' => 'Swedish (Fraktur)',
   tha        => 'Thai',
   tlg        => 'Tagalog',
   tur        => 'Turkish',
   ukr        => 'Ukranian',
   vie        => 'Vietnamese',
  );
  for ( glob "$tessdata/*$datasuffix" ) {

   # Weed out the empty language files
   if ( not -z $_ ) {
    my $code;
    if (/ ([\w\-]*) $datasuffix $/x) {
     $code = $1;
     $logger->info("Found tesseract language $code");
     if ( defined $iso639{$code} ) {
      $languages{$code} = $iso639{$code};
     }
     else {
      $languages{$code} = $code;
     }
    }
    else {
     $logger->info("Found unknown language file: $_");
    }
   }
  }
 }
 return \%languages;
}

sub hocr {

 # can't use the package-wide logger variable as we are in a thread here.
 ( my $class, my $file, my $language, $logger, my $pidfile ) = @_;
 my ( $tif, $cmd, $name, $path );
 Gscan2pdf::Tesseract->setup($logger) unless $setup;

 # Temporary filename for output
 my $suffix = $version >= 3 ? '.html' : '.txt';
 my $txt = File::Temp->new( SUFFIX => $suffix );
 ( $name, $path, undef ) = fileparse( $txt, $suffix );

 if ( $file !~ /\.tif$/x ) {

  # Temporary filename for new file
  $tif = File::Temp->new( SUFFIX => '.tif' );
  my $image = Image::Magick->new;
  $image->Read($file);
  $image->Write( filename => $tif );
 }
 else {
  $tif = $file;
 }
 if ( $version >= 3 ) {
  $cmd =
"echo tessedit_create_hocr 1 > hocr.config;tesseract $tif $path$name -l $language +hocr.config;rm hocr.config";
 }
 elsif ($language) {
  $cmd = "tesseract $tif $path$name -l $language";
 }
 else {
  $cmd = "tesseract $tif $path$name";
 }
 $logger->info($cmd);

 # File in which to store the process ID so that it can be killed if necessary
 $cmd = "echo $$ > $pidfile;$cmd" if ( defined $pidfile );

 my ( $out, $err ) = Gscan2pdf::Document::open_three($cmd);
 my $warnings = $out . $err;
 my $leading  = 'Tesseract Open Source OCR Engine';
 my $trailing = 'with Leptonica';
 $warnings =~ s/$leading v\d\.\d\d $trailing\n//x;
 $warnings =~ s/^Page\ 0\n//x;
 $logger->debug( 'Warnings from Tesseract: ', $warnings );

 return Gscan2pdf::Document::slurp($txt), $warnings;
}

1;

__END__
