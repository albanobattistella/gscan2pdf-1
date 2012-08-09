use warnings;
use strict;
use Test::More tests => 2;

BEGIN {
 use_ok('Gscan2pdf::Document');
 use Gtk2 -init;    # Could just call init separately
}

#########################

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);
our $logger = Log::Log4perl::get_logger;
Gscan2pdf::Document->setup($logger);

# Create test image
system('convert rose: test.pnm');

my $slist = Gscan2pdf::Document->new;
$slist->get_file_info(
 path              => 'test.pnm',
 finished_callback => sub {
  my ($info) = @_;
  $slist->import_file(
   info              => $info,
   first             => 1,
   last              => 1,
   finished_callback => sub {
    $slist->to_png(
     $slist->{data}[0][2],
     undef, undef, undef,
     sub {
      system("cp $slist->{data}[0][2]{filename} test.png");
      Gtk2->main_quit;
     }
    );
   }
  );
 }
);
Gtk2->main;

is( system('identify test.png'), 0, 'valid PNG created' );

#########################

unlink 'test.pnm', 'test.png';
Gscan2pdf::Document->quit();
