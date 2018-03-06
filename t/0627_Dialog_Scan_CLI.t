use warnings;
use strict;
use Test::More tests => 5;
use Glib qw(TRUE FALSE);    # To get TRUE and FALSE
use Gtk3 -init;             # Could just call init separately

BEGIN {
    use_ok('Gscan2pdf::Dialog::Scan::CLI');
}

#########################

my $window = Gtk3::Window->new;

Gscan2pdf::Translation::set_domain('gscan2pdf');
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);
my $logger = Log::Log4perl::get_logger;
Gscan2pdf::Frontend::CLI->setup($logger);

ok(
    my $dialog = Gscan2pdf::Dialog::Scan::CLI->new(
        title             => 'title',
        'transient-for'   => $window,
        'logger'          => $logger,
        'reload-triggers' => qw(mode),
    ),
    'Created dialog'
);
isa_ok( $dialog, 'Gscan2pdf::Dialog::Scan::CLI' );

$dialog->set( 'cache-options', TRUE );

$dialog->signal_connect(
    'process-error' => sub {
        my ( $widget, $process, $msg ) = @_;
        Gtk3->main_quit;
    }
);

my ( $signal, $signal2 );
$signal = $dialog->signal_connect(
    'reloaded-scan-options' => sub {
        $dialog->signal_handler_disconnect($signal);

        $signal = $dialog->signal_connect(
            'changed-options-cache' => sub {
                my ( $widget, $cache ) = @_;
                $dialog->signal_handler_disconnect($signal);
                my @keys = sort keys( %{ $cache->{test} } );
                is_deeply(
                    \@keys,
                    [ 'default', 'mode,Color', 'mode,Gray' ],
                    'starting with a non-default profile'
                );
                Gtk3->main_quit;
            }
        );
        $dialog->set_option(
            $dialog->get('available-scan-options')->by_name('mode'), 'Color' );
    }
);
$dialog->set( 'device-list', [ { 'name' => 'test' } ] );
$dialog->set( 'device', 'test' );

my $filename = 'scanners/Brother_DCP-7025';
my $output   = do { local ( @ARGV, $/ ) = $filename; <> };
my $options  = Gscan2pdf::Scanner::Options->new_from_data($output);
my $opt      = $options->by_name('contrast');
is( $dialog->value_for_active_option( TRUE, $opt ),
    FALSE, 'value_for_active_option() with defined value and inactive option' );

Gtk3->main;

#########################

__END__
