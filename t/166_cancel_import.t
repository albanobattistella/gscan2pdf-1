# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gscan2pdf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Test::More tests => 2;

BEGIN {
 use Gscan2pdf;
 use Gscan2pdf::Document;
 use Gtk2 -init;    # Could just call init separately
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Thumbnail dimensions
our $widtht  = 100;
our $heightt = 100;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);
our $logger = Log::Log4perl::get_logger;
Gscan2pdf->setup($logger);

# Create test image
system('convert rose: test.tif');
my $old = `identify test.tif`;

my $slist = Gscan2pdf::Document->new;
$slist->get_file_info(
 'test.tif',
 undef, undef, undef,
 sub {
  my ($info) = @_;
  my $pid = $slist->import_file(
   $info, 1, 1, undef, undef, undef, undef,
   undef,
   sub {
    is( defined( $slist->{data}[0] ), '', 'TIFF not imported' );
    $slist->import_file(
     $info, 1, 1, undef, undef, undef,
     sub {
      system("cp $slist->{data}[0][2]{filename} test.tif");
      Gtk2->main_quit;
     }
    );
   }
  );
  $slist->cancel($pid);
 }
);
Gtk2->main;

is( `identify test.tif`,
 $old, 'TIFF imported correctly after cancelling previous import' );

#########################

unlink 'test.tif';
Gscan2pdf->quit();