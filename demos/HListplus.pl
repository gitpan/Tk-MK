#!perl
use strict;
use Tk;

use Tk::ItemStyle;
use Tk::HListplus;
use Tk::DialogBox;

    my $mw = MainWindow->new(-width => 200);
	$mw->minsize(600,460);

	my ($col0, $col1) = (1, 1);
   
    # CREATE MY HLIST
    my $hlist = $mw->Scrolled('HListplus',
         -columns=>3, 
         -header => 1
         )->pack(-side => 'top', -expand => 'yes', -fill => 'both');

    # CREATE COLUMN HEADER 0
    my $headerstyle   = $hlist->ItemStyle('window', -padx => 0, -pady => 0);
   # my $headerstyle   = $hlist->ItemStyle('window', -padx => 0, -pady => 0);

   $hlist->headerCreate(0, 
 #  $hlist->header('create', 0, 
			-itemtype => 'resizebutton',
			#-style => $headerstyle,
			-text => 'Test Name', 
			-activeforeground => 'blue',
    );

    # CREATE COLUMN HEADER 1
    $hlist->header('create', 1,
			-itemtype => 'resizebutton',
		#	-style    =>$headerstyle,
			-text => 'Status', 
			-buttondownrelief => 'sunken',
			-activebackground => 'orange',
    );
    # CREATE COLUMN HEADER 2
    $hlist->header('create', 2,
			-itemtype => 'resizebutton',
		#	-style    =>$headerstyle,
			-text => 'dummy', 
			-command => sub { print "Hello, world!\n" }, 
    );
	foreach (qw/aaa bbb ccc ddd eee fff ggg/) {
		$hlist->add($_);
		$hlist->itemCreate($_, 0, -text => $_);
		$hlist->itemCreate($_, 1, -text => $_);
		$hlist->itemCreate($_, 2, -text => $_);
	}
	$hlist->bind('<Double-1>', sub {print "hiho\n"; } );

###########################
# and now burried within a Frame hierarchy

	my $test_frame = $mw->Frame (
		#-borderwidth => '2',
		#-relief => 'groove',
		-bg => 'red',
	)->pack(
		-side => 'top',
		-expand => '1',
		-fill => 'both',
		-anchor => 'w',
	);
	my $test_frame1 = $test_frame->Frame (
		#-borderwidth => '2',
		#-relief => 'groove',
		-bg => 'blue',
	)->pack(
		-side => 'top',
		-expand => '1',
		-fill => 'both',
		-anchor => 'w',
	);
	my $test_frame2 = $test_frame1->Frame (
		#-borderwidth => '2',
		#-relief => 'groove',
		-bg => 'green',
	)->pack(
		-side => 'top',
		-expand => '1',
		-fill => 'both',
		-anchor => 'w',
	);
	my $test_frame3 = $test_frame2->Frame (
		#-borderwidth => '2',
		#-relief => 'groove',
		-bg => 'yellow',
	)->pack(
		-side => 'top',
		-expand => '1',
		-fill => 'both',
		-anchor => 'w',
	);
	# CREATE MY HLIST
	# NOTE: Using $test_frame3 as the Hlist-Parent
	# the Double-Click does NOT work !!
	# But, Using $test_frame2 (one hierarchy up) DOES !! strange??!! 
    #my $hlist = $test_frame3->Scrolled('HListplus',
    my $hlist = $test_frame2->Scrolled('HListplus',
         -columns=>3, 
         -header => 1
         )->pack(-side => 'left', -expand => 'yes', -fill => 'both');

    # CREATE COLUMN HEADER 0
    my $headerstyle   = $hlist->ItemStyle('window', -padx => 0, -pady => 0);
   # my $headerstyle   = $hlist->ItemStyle('window', -padx => 0, -pady => 0);

   $hlist->headerCreate(0, 
 #  $hlist->header('create', 0, 
			-itemtype => 'resizebutton',
			#-style => $headerstyle,
			-text => 'Test Name', 
			-activeforeground => 'blue',
    );

    # CREATE COLUMN HEADER 1
    $hlist->header('create', 1,
			-itemtype => 'resizebutton',
		#	-style    =>$headerstyle,
			-text => 'Status', 
			-buttondownrelief => 'sunken',
			-activebackground => 'orange',
    );
    # CREATE COLUMN HEADER 2
    $hlist->header('create', 2,
			-itemtype => 'resizebutton',
		#	-style    =>$headerstyle,
			-text => 'dummy', 
			-command => sub { print "Hello, world!\n" }, 
    );
	foreach (qw/zzz yyy xxx www vvv uuu ttt/) {
		$hlist->add($_);
		$hlist->itemCreate($_, 0, -text => $_);
		$hlist->itemCreate($_, 1, -text => $_);
		$hlist->itemCreate($_, 2, -text => $_);
	}
	$hlist->bind('<Double-1>', sub {print "hello\n"; } );


MainLoop;
