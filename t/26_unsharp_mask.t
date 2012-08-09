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
system('convert rose: test.jpg');

my $slist = Gscan2pdf::Document->new;
$slist->get_file_info(
 path              => 'test.jpg',
 finished_callback => sub {
  my ($info) = @_;
  $slist->import_file(
   info              => $info,
   first             => 1,
   last              => 1,
   finished_callback => sub {
    $slist->unsharp(
     $slist->{data}[0][2],
     100, 5, 100, 0.5, undef, undef, undef,
     sub {
      $slist->save_image(
       path              => 'test2.jpg',
       list_of_pages     => [ $slist->{data}[0][2] ],
       finished_callback => sub { Gtk2->main_quit }
      );
     }
    );
   }
  );
 }
);
Gtk2->main;

is( system('identify test2.jpg'), 0, 'valid JPG created' );

#########################

unlink 'test.jpg', 'test2.jpg';
Gscan2pdf::Document->quit();
