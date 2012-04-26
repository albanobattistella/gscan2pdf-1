use warnings;
use strict;
use Test::More tests => 3;
use Gtk2 -init;    # Could just call init separately

BEGIN {
 use_ok('Gscan2pdf');
 use_ok('Gscan2pdf::Document');
 use PDF::API2;
}

#########################

Glib::set_application_name('gscan2pdf');

# Thumbnail dimensions
our $widtht  = 100;
our $heightt = 100;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);
our $logger = Log::Log4perl::get_logger;
Gscan2pdf->setup($logger);

# Create test image
system('convert rose: test.pnm');

my $slist = Gscan2pdf::Document->new;
$slist->get_file_info(
 'test.pnm',
 undef, undef, undef,
 sub {
  my ($info) = @_;
  $slist->import_file(
   $info, 1, 1, undef, undef, undef,
   sub {
    $slist->save_pdf( 'test.pdf', [ $slist->{data}[0][2] ],
     undef, undef, undef, undef, undef, sub { Gtk2->main_quit } );
   }
  );
 }
);
Gtk2->main;

is( system('identify test.pdf'), 0, 'valid PDF created' );

#########################

unlink 'test.pnm', 'test.pdf';
Gscan2pdf->quit();
