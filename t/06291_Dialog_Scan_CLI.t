use warnings;
use strict;
use Test::More tests => 1;
use Glib qw(TRUE FALSE);    # To get TRUE and FALSE
use Gtk3 -init;             # Could just call init separately
use Image::Sane ':all';     # To get SANE_* enums

BEGIN {
    use Gscan2pdf::Dialog::Scan::CLI;
}

#########################

my $window = Gtk3::Window->new;

Gscan2pdf::Translation::set_domain('gscan2pdf');
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);
my $logger = Log::Log4perl::get_logger;
Gscan2pdf::Frontend::CLI->setup($logger);

my $dialog = Gscan2pdf::Dialog::Scan::CLI->new(
    title           => 'title',
    'transient-for' => $window,
    'logger'        => $logger
);

# test setting paper-formats before the scan options are fetched
$dialog->set( 'paper-formats',
    { '10x10' => { l => 0, y => 10, x => 10, t => 0, } } );

my $profile_changes = 0;
$dialog->{signal} = $dialog->signal_connect(
    'reloaded-scan-options' => sub {
        $dialog->signal_handler_disconnect( $dialog->{signal} );
        pass('Initialised scan dialog after setting paper formats');
        Gtk3->main_quit;
    }
);
$dialog->set( 'device', 'test' );
$dialog->scan_options;
Gtk3->main;

__END__
