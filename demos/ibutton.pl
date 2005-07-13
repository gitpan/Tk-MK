#!/home/opcdev/local/bin/perl -w

##############################################
### Use
##############################################
use strict;

# graphical stuff
use Tk;
use Tk::widgets qw/Button/;
use Tk::IButton;

# Create a new TopLevelWidget
my $mw = MainWindow::->new;

	#-------------------------------------
	my $downangle_data = <<'downangle_EOP';
		/* XPM */
		static char *cbxarrow[] = {
		"14 9 2 1",
		". c none",
		"X c black",
		"..............",
		"..............",
		".XXXXXXXXXXXX.",
		"..XXXXXXXXXX..",
		"...XXXXXXXX...",
		"....XXXXXX....",
		".....XXXX.....",
		"......XX......",
		"..............",
		};
downangle_EOP

my $downangle = $mw->Pixmap( -data => $downangle_data);



##########################################################
# Creation procedures
##########################################################
my $var = 'bttn-text';

$mw->title("Test");
	my $bt1 = $mw->Buttonplus(
		-text => 'Enable',
		-image => $downangle,
        #-bitmap => 'error',
		-command => \&bttn_pressed_cb1,
		#-borderwidth => '12',
		#-relief => 'ridge',
		#-bg => 'orange',
		#-fg => 'green',
		-textvariable => \$var,
		-side => 'bottom',
		#-activeforeground => 'skyblue',
	)->pack(-padx => 50, -pady => 50);
	my $bt2 = $mw->Button(
		-text => 'Disable',
		-command => [\&bttn_pressed_cb2, $bt1],
		#-image => $downangle,
	)->pack;

#	
MainLoop();


sub bttn_pressed_cb1
{
	print "bttn_pressed_cb1: hallo: [@_]\n";
	
}
sub bttn_pressed_cb2
{
	print "bttn_pressed_cb2: hallo: [@_]\n";
	$_[0]->configure(-state => ($_[0]->cget('-state') eq 'normal' ? 'disabled' : 'normal'));
}
