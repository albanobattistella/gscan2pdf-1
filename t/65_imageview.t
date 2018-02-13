use Test::More tests => 35;

BEGIN {
    use Glib qw/TRUE FALSE/;
    use Gtk3 -init;
    use_ok('Gscan2pdf::ImageView');
}

#########################

my $view = Gscan2pdf::ImageView->new;
isa_ok( $view, 'Gscan2pdf::ImageView' );
is( $view->get_tool, 'dragger', 'get_tool() defaults to dragger' );

system('convert rose: test.jpg');
$signal = $view->signal_connect(
    'offset-changed' => sub {
        my ( $widget, $x, $y ) = @_;
        is $x, 0,  'emitted offset-changed signal x';
        is $y, 11, 'emitted offset-changed signal y';
    }
);
$view->set_pixbuf( Gtk3::Gdk::Pixbuf->new_from_file('test.jpg'), TRUE );
is_deeply( $view->get_viewport,
    { x => 0, y => 11.9999998044223, width => 1, height => 1 },
    'get_viewport' );

SKIP: {
    skip 'not yet', 2;

    isa_ok( $view->get_draw_rect, 'Gtk3::Gdk::Rectangle' );

    ok( $view->get_check_colors, 'get_check_colors()' );
}

isa_ok( $view->get_pixbuf, 'Gtk3::Gdk::Pixbuf', 'get_pixbuf()' );
is_deeply( $view->get_pixbuf_size, { width => 70, height => 46 },
    'get_pixbuf_size' );
is_deeply( $view->get_allocation, { x => -1, y => -1, width => 1, height => 1 },
    'get_allocation' );
is_deeply( $view->get_zoomed_size, { width => 1, height => 1 },
    'get_zoomed_size' );

is( $view->get_zoom, 0.0142857143655419, 'get_zoom()' );

$signal = $view->signal_connect(
    'zoom-changed' => sub {
        my ( $widget, $zoom ) = @_;
        is $zoom, 1, 'emitted zoom-changed signal';
    }
);
$view->set_zoom(1);

$signal = $view->signal_connect(
    'selection-changed' => sub {
        my ( $widget, $selection ) = @_;
        is_deeply(
            $selection,
            { x => 10, y => 10, width => 10, height => 10 },
            'emitted selection-changed signal'
        );
    }
);
$view->set_selection( { x => 10, y => 10, width => 10, height => 10 } );
is_deeply( $view->get_selection,
    { x => 10, y => 10, width => 10, height => 10 },
    'get_selection' );

$signal = $view->signal_connect(
    'tool-changed' => sub {
        my ( $widget, $tool ) = @_;
        is $tool, 'selector', 'emitted tool-changed signal';
    }
);
$view->set_tool('selector');

SKIP: {
    skip 'not yet', 5;
    ok(
        Gscan2pdf::ImageView::Zoom->get_min_zoom <
          Gscan2pdf::ImageView::Zoom->get_max_zoom,
'Ensure that the gtkimageview.zooms_* functions are present and work as expected.'
    );

    is( defined $view->get_black_bg, TRUE, 'get_black_bg()' );

    is( defined $view->get_show_frame, TRUE, 'get_show_frame()' );

    is( defined $view->get_interpolation, TRUE, 'get_interpolation()' );

    is( defined $view->get_show_cursor, TRUE, 'get_show_cursor()' );
}

eval { $view->set_pixbuf( 'Hi mom!', TRUE ) };
like( $@, qr/type/,
'A TypeError is raised when set_pixbuf() is called with something that is not a pixbuf.'
);

$view->set_pixbuf( undef, TRUE );
is( defined $view->get_pixbuf,   FALSE, 'correctly cleared pixbuf' );
is( defined $view->get_viewport, FALSE, 'correctly cleared viewport' );

SKIP: {
    skip 'not yet', 10;

    ok( !$view->get_draw_rect, 'correctly cleared draw rectangle' );

    $view->size_allocate( Gtk3::Gdk::Rectangle->new( 0, 0, 100, 100 ) );
    $view->set_pixbuf(
        Gtk3::Gdk::Pixbuf->new( GDK_COLORSPACE_RGB, FALSE, 8, 50, 50 ) );
    my $rect = $view->get_viewport;
    ok(
        (
                  $rect->x == 0 and $rect->y == 0
              and $rect->width == 50
              and $rect->height == 50
        ),
        'Ensure that getting the viewport of the view works as expected.'
    );

    can_ok( $view, qw(get_check_colors) );

    $rect = $view->get_draw_rect;
    ok(
        (
                  $rect->x == 25 and $rect->y == 25
              and $rect->width == 50
              and $rect->height == 50
        ),
        'Ensure that getting the draw rectangle works as expected.'
    );

    $view->set_pixbuf(
        Gtk3::Gdk::Pixbuf->new( GDK_COLORSPACE_RGB, FALSE, 8, 200, 200 ) );
    $view->set_zoom(1);
    $view->set_offset( 0, 0 );
    $rect = $view->get_viewport;
    ok( ( $rect->x == 0 and $rect->y == 0 ),
        'Ensure that setting the offset works as expected.' );

    $view->set_offset( 100, 100, TRUE );
    $rect = $view->get_viewport;
    ok( ( $rect->x == 100 and $rect->y == 100 ),
        'Ensure that setting the offset works as expected.' );

    $view->set_transp( 'color', 0xff0000 );
    my ( $col1, $col2 ) = $view->get_check_colors;
    ok(
        ( $col1 == 0xff0000 and $col2 == 0xff0000 ),
        'Ensure that setting the views transparency settings works as expected.'
    );
    $view->set_transp('grid');

    ok( defined Glib::Type->list_values('Gscan2pdf::ImageView::Transp'),
        'Check GtkImageTransp enum.' );
}
unlink 'test.jpg';