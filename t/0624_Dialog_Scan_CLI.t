use warnings;
use strict;
use Test::More tests => 5;
use Glib qw(TRUE FALSE);    # To get TRUE and FALSE
use Gtk2 -init;             # Could just call init separately
use Sane 0.05;              # To get SANE_* enums

BEGIN {
    use_ok('Gscan2pdf::Dialog::Scan::CLI');
}

#########################

my $window = Gtk2::Window->new;

Glib::set_application_name('gscan2pdf');
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);
my $logger = Log::Log4perl::get_logger;
Gscan2pdf::Frontend::CLI->setup($logger);

ok(
    my $dialog = Gscan2pdf::Dialog::Scan::CLI->new(
        title           => 'title',
        'transient-for' => $window,
        'logger'        => $logger
    ),
    'Created dialog'
);
isa_ok( $dialog, 'Gscan2pdf::Dialog::Scan::CLI' );

my $signal;
$signal = $dialog->signal_connect(
    'reloaded-scan-options' => sub {
        $dialog->signal_handler_disconnect($signal);

        $dialog->set( 'current-scan-options', [ { 'invert-endianess' => 0 } ] );

        $dialog->signal_connect(
            'new-scan' => sub {
                my ( $widget, $n ) = @_;
                is( $n, 1, 'error-free scan despite illegal option' );

#########################

                $dialog = Gscan2pdf::Dialog::Scan::CLI->new(
                    title           => 'title',
                    'transient-for' => $window,
                    'logger'        => $logger
                );

                $signal = $dialog->signal_connect(
                    'reloaded-scan-options' => sub {
                        $dialog->signal_handler_disconnect($signal);

                        $dialog->set( 'current-scan-options',
                            [ { mode => 'Gray' }, { 'invert-endianess' => 0 } ]
                        );

                        $dialog->signal_connect(
                            'new-scan' => sub {
                                my ( $widget, $n ) = @_;
                                is( $n, 1,
'error-free scan despite illegal option following an ignored one'
                                );
                                Gtk2->main_quit;
                            }
                        );
                        $dialog->signal_connect(
                            'process-error' => sub {
                                my ( $widget, $process, $msg ) = @_;
                                Gtk2->main_quit;
                            }
                        );
                        $dialog->set( 'num-pages',             1 );
                        $dialog->set( 'page-number-increment', 1 );
                        $dialog->scan;
                    }
                );
                $dialog->set( 'device-list', [ { 'name' => 'test' } ] );
                $dialog->set( 'device', 'test' );
            }
        );
        $dialog->set( 'num-pages',             1 );
        $dialog->set( 'page-number-increment', 1 );
        $dialog->scan;
    }
);
$dialog->set( 'device-list', [ { 'name' => 'test' } ] );
$dialog->set( 'device', 'test' );

#########################

Gtk2->main;

__END__