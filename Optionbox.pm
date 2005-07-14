######################################## SOH ###########################################
## Function : Replacement for Tk:Optionmenu (more flexible handling for 'image_only')
##
## Copyright (c) 2002-2005 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V1.0	30-Aug-2002 	Class derived from original Optionmenu. MK
##            V1.1  19-Nov-2002 	Added popup() function MK.
##            V1.2  07-Nov-2003 	Added -tearoff option MK.
##            V1.3  16-Dec-2004 	Added multicolumn & activate option (-rows/-activate option) MK.
##            V1.4  14-Jun-2005 	Added second hierarchy for the options,
##                                  Optionformat: [ label, value], [[keylabel, \@subopts], undef], [], ... MK.
##
######################################## EOH ###########################################
package Tk::Optionbox;

##############################################
### Use
##############################################
use Tk;
use Tk::Menubutton;
use Tk::Menu;

use strict;
use Carp;

use vars qw ($VERSION);
$VERSION = '1.4';

use base qw (Tk::Derived Tk::Menubutton);

########################################################################
Tk::Widget->Construct ('Optionbox');

#---------------------------------------------
sub ClassInit {
	my ($class, $window) = (@_);
	
	$class->SUPER::ClassInit($window);
	$window->bind ($class, '<Control-Tab>','focusNext');
	$window->bind ($class, '<Control-Shift-Tab>','focusPrev');
	$window->bind ($class, '<Tab>', 'focus');
}

#---------------------------------------------
sub Populate {
	my ($this, $args) = @_;

	# Check whether we're in backward compatibility mode
	unless (defined $args->{-image}) {
		$args->{-indicatoron} = 1;
		$this->{no_image} = 1;
	}

	$this->SUPER::Populate ($args);
	
	# Create a Closure for saving the current value
	my $var = delete $args->{-textvariable};
	unless (defined $var) {
		my $gen = undef;
		$var = \$gen;
	}
	$this->configure(-textvariable => $var);

	#Create the widget	
	my ($menu) = $this->Menu();
	$this->configure(-menu => $menu);
	
	$this->ConfigSpecs(
    	-takefocus			=> ['SELF', 'takefocus', 'Takefocus', 1],
    	-highlightthickness	=> ['SELF', 'highlightThickness', 'HighlightThickness', 1],
    	-borderwidth		=> [['SELF', 'PASSIVE'], 'borderwidth', 'BorderWidth', 2],
    	-relief				=> [['SELF', 'PASSIVE'], 'relief', 'Relief', 'raised'],
    	-anchor				=> [['SELF', 'PASSIVE'], 'anchor', 'Anchor', 'w'],
     	-direction 			=> [['SELF', 'PASSIVE'], 'direction', 'Direction', 'flush'],
    	-font				=> [['SELF', $menu], undef, undef, undef],
    	-variable 			=> ['PASSIVE', undef, undef, undef],
    	-tearoff 			=> ['PASSIVE', 'tearoff', 'TearOff', 1],
    	-activate 			=> ['PASSIVE', 'activate', 'Activate', 1],
    	-rows	 			=> ['PASSIVE', 'rows', 'Rows', 20],
    	-options 			=> ['METHOD',  undef, undef, undef],
    	-command 			=> ['CALLBACK',undef,undef,undef],
	);

	# configure -variable and -command now so that when -options
	# is set by main-line configure they are there to be set/called.
	$this->configure(-variable => $var) if ($var = delete $args->{-variable});
	$this->configure(-command  => $var) if ($var = delete $args->{-command});
}
sub popup
{
	my $this = shift;
	my $menu = $this->menu;
	my $xpos = $this->rootx;
	my $ypos = $this->rooty;
	$menu->post($xpos, $ypos);
}

sub set_option
{
	my ($this, $label, $val) = @_;
	$val = $label if @_ == 2;
	my $var = $this->cget(-textvariable);
	$$var = $label;
	$var = $this->cget(-variable);
	$$var = $val if $var;
	$this->Callback(-command => $val);
}

sub add_options
{
	# Parameters
	my $this = shift;
	
	# Locals
	my ($menu, $var, $old, $width, %hash, $first, $i, $subopts, $subopt, $sublabel,
		$maxrows, $activate, $val, $label, $len, $columnbreak);

	$menu = $this->menu;
	$var = $this->cget(-textvariable);
	$width = $this->cget('-width');
	$maxrows = $this->cget('-rows');
	$activate = $this->cget('-activate');
	$old = $$var; $i = 0;
	#print "activate is >$activate<\n";
	
	#print "menu-background is >" , $menu->cget('-background'), "<\n";
	#print "main-background is >" , $this->toplevel->cget('-background'), "<\n";
	$menu->configure(-tearoff => $this->cget('-tearoff') );
	$menu->configure(-background => $this->toplevel->cget('-background') );
	while (@_) {
		$val = shift;
		$label = $val;
		if (ref $val) {
			($label, $val) = @$val;
		}
		if (ref $label) {
			($label, $subopts) = @$label;
		}
		else {
			undef $subopts;
		}

		$columnbreak = $i ? (($i % $maxrows) ? 0 : 1) : 0;
		$len = length($label);
		$width = $len if (!defined($width) || $len > $width);
		if ($subopts) {
			my $submenu = $menu->cascade(
					-label => $label,
					-tearoff => '0',
			);
			foreach $subopt (@$subopts) {
				$sublabel = $label . '/' . $subopt->[0];
				$submenu->command(
						-label => $subopt->[0],
						-command => [ $this , 'set_option', $sublabel, $subopt->[1] ],
				);
				$hash{$sublabel} = $subopt->[1];
			}
		}
		else {
			$menu->command(
					-label => $label,
					-command => [ $this , 'set_option', $label, $val ],
					-columnbreak => $columnbreak,
			);
		}
		$hash{$label} = $val;
		$first = $label unless defined $first;
		$i++;
	}
	if (!defined($old) || !exists($hash{$old})) {
		$this->set_option($first, $hash{$first}) if defined $first and $activate;
	}
	if ($this->{no_image}) {
		$this->configure('-width' => $width);
	}
}

sub options {
	my ($this,$opts) = @_;
	if (@_ > 1) {
		$this->menu->delete(0,'end');
		$this->add_options(@$opts);
	}
	else {
		return $this->_cget('-options');
	}
}

########################################################################
1;
__END__

=cut

=head1 NAME

Tk::Optionbox - Another pop-up option-widget (with second-level selections)

=head1 SYNOPSIS

    use Tk;
    use Tk::Optionbox

    my $current_class;
    my @all_classes = qw(cat dog bird);
    my $demo_xpm;
	
    my $mw = MainWindow->new();
	
    # prepare some graphics
    setup_pixmap();

    # create a demo 
    my $optionbox = $mw->Optionbox (
        -text     => "Class",
        -image    => $demo_xpm, # use this line for personal pics or
        #-bitmap  => '@' . Tk->findINC('cbxarrow.xbm'));
        -command  => \&class_cb,
        -options  => [ @all_classes ],
        -variable => \$current_class, 
		-tearoff  => '1',
		-rows => 10,
		-activate => '0',
    )->pack;
	
    Tk::MainLoop;
	
    sub class_cb
    {
        print "class_cb called with [@_], \$current_class = >$current_class<\n";
    }
    sub setup_pixmap
    {
        my $cbxarrow_data = <<'cbxarrow_EOP';
	/* XPM */
	static char *cbxarrow[] = {
	"11 14 2 1",
	". c none",
	"  c black",
	"...........",
	"....   ....",
	"....   ....",
	"....   ....",
	"....   ....",
	"....   ....",
	".         .",
	"..       ..",
	"...     ...",
	"....   ....",
	"..... .....",
	"...........",
	".         .",
	".         ."
	};
cbxarrow_EOP

        $demo_xpm = $mw->Pixmap( -data => $cbxarrow_data);
    }
	

=head1 DESCRIPTION

Another menu button style widget that can replace the default Optionmenu.
Useful in applications that want to use a more flexible option menu. 
It's based on the default TK::Optionmenu, beside that it can handle menubuttons
without the persistent, ugly B<menu-indicator>, suitable for perl Tk800.x (developed with Tk800.024).

You can tie a scalar-value to the Optionbox widget, enable/disable it,
assign a callback, that is invoked each time the Optionbox is changed,
as well as set Option-values and configure any of the options
understood by Tk::Frame(s) like -relief, -bg, ... .
(see docs of TK::Optionmenu) for details

=head1 METHODS

=over 4

=item B<set_option()>

'set_option($newvalue)' allows to set/reset the widget methodically,
$newvalue will be aplied to the labeltext (if visible) and the internal
variable regardless if it is a list previously store in options.

You should prefer interacting with the widget via a variable.


=item B<add_options()>

'add_options(@newoptions)' allows to enter additonal options that will be
displayed in the pull-down menu list.

You should prefer to use a Configure ('-options' => ...).

NOTE: Unless You specify -activate => 0 for the widget each time you use
add_options the first item will be set to be the current one and any assigned
callback gets called.

=item B<popup()>

'popup()' allows to immediately popup the menu to force the user
to do some selection.

=back


=head1 OPTIONS

=over 4

=item B<-variable>

'-variable' allows to specify a reference to a scalar-value.
Each time the widget changes by user interaction, the variable
is changed too. Every variable change is immediately mapped in the
widget too.


=item B<-command>

'-command' can be used to supply a callback for processing after
each change of the Checkbox value.


=item B<-image>

'-image' can be used to supply a personal bitmap for the menu-button.
In difference to the original Optionmenu the std. menu-indicator is
switched off, if a graphic/bitmap is used , although it might
be re-enabled manually with a B<'-indicatoron =\> 1'> setting.
If no image and no bitmap is specified the text given with B<'-text'>
or the current selected optiontext is displayed in the button.

=item B<-options>

'-options' expects a reference to a list of options.

NOTE: Unless You specify -activate => 0 for the widget each time you use
add_options the first item will be set to be the current one and any assigned
callback gets called.
NOTE: Version 1.4 adds a secondary level to selections: instead of the
plain format [ label, value ], [ label, value ], [ label, value ],
you must use this format: [ label, value ], [[keylabel, \@subopts], undef], [ label, value ],

=item B<-activate>

'-activate' expects 0/1 and rules whether the first item applied with -options gets
set 'current'. see NOTE above.

=item B<-rows>

'-rows' defines after how many entries the list gets split into another row. default is 25.

=item B<-tearoff>

'-tearoff' defines whether the pop'd up list will have a tear-off entry at first position.

=back

Please see the TK:Optionmenu docs for details on all other aspects
of these widgets.


=head1 AUTHORS

Michael Krause, <KrauseM@gmx.net>

This code may be distributed under the same conditions as Perl.

V1.4  (C) June 2005

=cut

###
### EOF
###

