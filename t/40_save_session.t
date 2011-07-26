# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gscan2pdf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN {
  use Gscan2pdf;
  use Gscan2pdf::Document;
  use File::Basename;         # Split filename into dir, file, ext
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Thumbnail dimensions
our $widtht  = 100;
our $heightt = 100;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
our $logger = Log::Log4perl::get_logger;
my $prog_name = 'gscan2pdf';
use Locale::gettext 1.05;    # For translations
our $d = Locale::gettext->domain($prog_name);
Gscan2pdf->setup($d, $logger);

# Create test image
system('convert rose: test.pnm');

my $slist = Gscan2pdf::Document->new;
$slist->get_file_info( 'test.pnm', sub {}, sub {}, sub {
 my ($info) = @_;
 $slist->import_file( $info, 1, 1, sub {}, sub {}, sub {
  $slist->{data}[0][2]{hocr} = 'The quick brown fox';
  $slist->save_session(dirname( $slist->{data}[0][2]{filename} ), 'test.gs2p');
  Gtk2->main_quit;
 })
});
Gtk2->main;

is(`file test.gs2p`, "test.gs2p: gzip compressed data\n", 'Session file created');
cmp_ok( -s 'test.gs2p', '>', 0, 'Non-empty Session file created' );

#########################

unlink 'test.pnm';
Gscan2pdf->quit();