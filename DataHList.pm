######################################## SOH ###########################################
## Function : Additional Tk Class for Listbox-type HList with Data per Item, Sorting
##
## Copyright (c) 2002-2005 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V1.00	10-Dec-2002 	Class adopted from ExtListbox. MK
##            V1.01 10-Jan-2003 	Added -databackground(color). MK
##            V1.02 19-Jan-2004 	Added numeric sorting for column 2. MK
##            V1.1  13-May-2005 	Added missing data for sorting in column 2. MK
##
######################################## EOH ###########################################
package Tk::DataHList;

##############################################
### Use
##############################################
#use Tk::HList;
use Tk::HListplus;
use Tk::ItemStyle;
use Tk qw(Ev);

use strict;
use Carp;

use vars qw ($VERSION);
$VERSION = '1.1';

#use base qw (Tk::Derived Tk::HList);
use base qw (Tk::Derived Tk::HListplus);

########################################################################
Construct Tk::Widget 'DataHList';

#---------------------------------------------
# internal Setup function
#---------------------------------------------
sub ClassInit
{
    my ($class, $window) = @_;

    $class->SUPER::ClassInit($window);

	# Note these keyboard-Keys are only usable, if the widget gets 'focus'
	$window->bind ($class, '<Control-Key-bracketleft>', [\&viewtype, 'withdata']);
	$window->bind ($class, '<Control-Key-bracketright>', [\&viewtype, 'normal']);
	# Update the view after mapping
	$window->bind ($class, '<Map>', \&map_cb);
}

#---------------------------------------------
# internal Setup function
#---------------------------------------------
sub CreateArgs
{
    my ($class, $window, $args) = @_;
	
	# Necessarily Patch Columns
	my %args;	
	(%args) = ( -columns => '2') unless defined $args->{-columns};
    ($class->SUPER::CreateArgs($window, $args), %args);
}

#---------------------------------------------
# internal Setup function
#---------------------------------------------
sub Populate
{
    my ($this, $args) = @_;		

	my $data_background = delete $args->{-databackground};
	$data_background = $this->cget ('-background') unless defined $data_background;
	my $style = delete $args->{-datastyle};
	$style = $this->toplevel->ItemStyle ('text' ,
							-anchor => 'e',
							-background => $data_background,
	) unless defined $style;

	# Check whether we want numeric sorting
	$this->{m_numeric_primary_sort}   = delete $args->{-numeric_primary_sort} || 0;
	$this->{m_numeric_secondary_sort} = delete $args->{-numeric_secondary_sort} || 0;
	
	# Reroute any size_call_back
	my $sizecmd = delete $args->{-sizecmd};
	$sizecmd = sub { return 1 } unless defined $sizecmd;
	$args->{-sizecmd} = [\&resize_cb, $this ];

	#INvoke Superclass fill func
    $this->SUPER::Populate($args);

	#
	$this->ConfigSpecs(
	#default listbox options
		-pady					=> [['SELF', 'PASSIVE'], 'pady', 'Pad', '0'],
    	-sizecmd_cb 	        => ['CALLBACK',undef, undef, $sizecmd],
	# new, additional optiona
		-viewtype				=> ['METHOD', 'ViewType', 'viewType', undef],		
 		-datastyle				=> [['SELF', 'PASSIVE'], 'datastyle', 'datastyle', $style],
	);
		
	# Internal Presets
	$this->{m_firstpath}	= undef;
	$this->{m_datastyle}	= $style;
	$this->{m_viewtype} 	= '---';	
}

#---------------------------------------------
# OVERRIDE: new ADD function
#---------------------------------------------
sub add 
{
	# Locals
	my ($this, $path, %args, $data, $datastyle);

	# Parameters
	$this = shift;
	$path = shift;
	%args = @_;
	
	# Do we have anything at all to insert ?
	return unless @_;

	# Prepare the data and it's style
	$data		= (defined $args{-data}) ? delete $args{-data} : 'undef';
	$datastyle	= (defined $args{-datastyle}) ? delete $args{-datastyle} : $this->{m_datastyle};

	# now add it as desired
	$this->SUPER::add($path, -data => $data);
	$this->SUPER::itemCreate($path, 0, %args);
	# and a second column for the data
	$this->SUPER::itemCreate($path, 1,
					-itemtype => 'text',
					-text => $data,
					-style => $datastyle,
	);
	# store it internally
	$this->{m_firstpath} = $path unless defined $this->{m_firstpath};
	# store it internally
	$this->{m_datastyle}{$path} = $datastyle;
	
	# Install the 'normal view after we have something on the screen..
	$this->viewtype($this->{m_viewtype});
}

#---------------------------------------------
# OVERRIDE: new DELETE function
#---------------------------------------------
sub delete
{
	# Parameters
	my ($this, $what, $path) = @_;

	if ($what eq 'all') {
		# Clear the internal storage
		$this->{m_firstpath}	= undef;
		# Delete it
		$this->SUPER::delete($what);
	}
	else {
		# Clear the internal storage
		if (defined $this->{m_firstpath}) {
			if ($path eq $this->{m_firstpath}) {
				$this->{m_firstpath} = undef;
			}
		}
		# Delete it
		$this->SUPER::delete($what, $path);
	}
}

#---------------------------------------------
# ADD-ON: reordering function
#---------------------------------------------
sub reverse
{
	# Locals
	my ($this, @paths, $path, @allitems, $opt, $value, %items, %data, %hidden);

	# Parameters
	$this = shift;

	# safety check
	return unless defined $this->{m_firstpath};
	# Retrieve the contents
	$path = $this->{m_firstpath};
	while (defined $path && $path ne "") {
		push @paths, $path;
		#----------------------------------
		@allitems = $this->itemConfigure($path, 0);
		my %args = ();
		foreach (@allitems) {
			$opt = $_->[0]; $value = $_->[4];
			if (defined $value && $value ne "") {
				$args{$opt} = $value;
			}
		}	
		$items{$path} = \%args;
		#----------------------------------
		my $data = $this->infoData($path);
		#print "retrieved data $data<\n";
		$data{$path} = $data;
		#----------------------------------
		my $hidden = $this->infoHidden($path);
		#print "retrieved hidden $hidden<\n";
		$hidden{$path} = $hidden;
		#----------------------------------
		$path = $this->infoNext($path);
	}
	# delete it
	$this->delete('all');

	$this->{m_firstpath} = undef;
		
	# Reverse, refill it
	foreach ( reverse @paths ) {
		$this->add( $_, -data => $data{$_},
					%{$items{$_}} );
		if ($hidden{$_} == 1) {
			$this->hide('entry', $_);
		}
		$this->{m_firstpath} = $_ unless defined $this->{m_firstpath};
	}
}

#---------------------------------------------
# ADD-ON: sorting function
#---------------------------------------------
sub sort
{
	# Locals
	my ($this, $mode, @paths, $path, @allitems, $opt, $value, %items, %data, %hidden,
		 @sortarray, @tmparray);
	#print "begin of sort\n";

	# Parameters
	$this	= shift;
	$mode	= shift; $mode = 'ascending' unless defined $mode;

	# safety check
	return unless defined $this->{m_firstpath};

	# Retrieve the contents
	$path = $this->{m_firstpath};
	while (defined $path && $path ne "") {
		push @paths, $path;
		#----------------------------------
		@allitems = $this->itemConfigure($path, 0);
		my %args = ();
		foreach (@allitems) {
			$opt = $_->[0]; $value = $_->[4];
			#$opt = 'undef' unless defined $opt;
			#$value = 'undef' unless defined $value;
			#print "retrieved \$opt = >$opt<, \$value = >", defined $value ? $value : 'undef', ,"<\n";
			if (defined $value && $value ne "") {
				$args{$opt} = $value;
			}
		}	
		$items{$path} = \%args;
		#----------------------------------
		my $data = $this->infoData($path);
		#print "retrieved data $data<\n";
		$data{$path} = $data;
		#----------------------------------
		my $hidden = $this->infoHidden($path);
		#print "retrieved hidden $hidden<\n";
		$hidden{$path} = $hidden;
		#----------------------------------
		$path = $this->infoNext($path);
	}
	# delete it
	$this->delete('all');
	
	foreach (@paths) {
		push @sortarray, [ $_, $items{$_}->{-text}, $data{$_} ];
	}

	# sort it
	if ($mode =~ /ascending/i) {
		if ($mode =~ /secondary/i) {
			if ($this->{m_numeric_secondary_sort}) {
				@tmparray = sort secondary_numeric @sortarray;
			}
			else {
				@tmparray = sort secondary @sortarray;
			}
		}
		else {
			if ($this->{m_numeric_primary_sort}) {
				@tmparray = sort primary_numeric @sortarray;
			}
			else {
				@tmparray = sort primary @sortarray;
			}
		}
	}
	elsif ($mode =~ /descending/i) {
		if ($mode =~ /secondary/i) {
			if ($this->{m_numeric_secondary_sort}) {
				@tmparray = sort rev_secondary_numeric @sortarray;
			}
			else {
				@tmparray = sort rev_secondary @sortarray;
			}
		}
		else {
			if ($this->{m_numeric_primary_sort}) {
				@tmparray = sort rev_primary_numeric @sortarray;
			}
			else {
				@tmparray = sort rev_primary @sortarray;
			}
		}
	}
	else {
		return;
	}
	
	#
	$this->{m_firstpath} = undef;	
	
	# refill it
	foreach ( @tmparray ) {
		$path = $_->[0];
		$this->add( $path, -data => $data{$path},
					%{$items{$path}}, -datastyle => $this->{m_datastyle}{$path} );
		if ($hidden{$path} == 1) {
			$this->hide('entry', $path);
		}
		$this->{m_firstpath} = $path unless defined $this->{m_firstpath};
	}
}
sub secondary
{
	$a->[2] cmp $b->[2];
}
sub rev_secondary
{
	$b->[2] cmp $a->[2];
}
sub secondary_numeric
{
	$a->[2] <=> $b->[2];
}
sub rev_secondary_numeric
{
	$b->[2] <=> $a->[2];
}
sub primary
{
	$a->[1] cmp $b->[1];
}
sub rev_primary
{
	$b->[1] cmp $a->[1];
}
sub primary_numeric
{
	$a->[1] <=> $b->[1];
}
sub rev_primary_numeric
{
	$b->[1] <=> $a->[1];
}

#---------------------------------------------
# ADD-ON: trace any viewtype updates
# supported values are 'normal', 'withdata'
#---------------------------------------------
sub viewtype
{
	# Parameters
	my ($this, $viewtype)  = @_;
	# if we're not in a cget we might consider changing the value
	if (defined $viewtype) {
		#print "we're in viewtype with $viewtype\n";
		# allow only 'normal' &  'withdata'...
		if ($viewtype =~ /withdata/i ) {
			$viewtype = 'withdata';
		}
		else {
			$viewtype = 'normal';
		}
		#
		#print "internal viewtype is $this->{m_viewtype}\n";
		if ($this->{m_viewtype} ne $viewtype) {
			$this->{m_viewtype} = $viewtype;
			$this->setup_view();
		}
	}
	# needed for cget
	return $this->{m_viewtype};
}

#---------------------------------------------
# ADD-ON: setup_view: display function
#---------------------------------------------
sub setup_view 
{
	# Parameters
	my $this = shift;

	# Locals
	my (@bb, $needsize);
	#print "firstpath = ", (defined $this->{m_firstpath}) ? $this->{m_firstpath} : "undef";
	return unless defined $this->{m_firstpath};
	#print "in setupview\n";
	if ($this->{m_viewtype} eq 'withdata') {
		$this->columnWidth(1, '');
		$needsize = $this->columnWidth(1);
	}
	else {
		$this->columnWidth(1, 0);
		$needsize = 0;
	}
	@bb = $this->infoBbox($this->{m_firstpath});
	# Fast hack to avoid empty bbox due to invisible first item
	if (@bb == 0) {
		my $path = $this->nearest(10);
		@bb = $this->infoBbox($path);
	}
	#print "bbox is @bb<, needsize is $needsize\n";
	if (@bb) {
		$this->columnWidth(0, $bb[2] - $bb[0] - $needsize);
	}
}

#---------------------------------------------
# ADD-ON: new resizxing function
#---------------------------------------------
sub resize_cb
{
    my ($this) = shift;
	return unless defined $this->{m_firstpath};
	return unless $this->viewable;
	
	my $path0 = $this->{m_firstpath};
	my @bb = $this->infoBbox($path0);
	#print "bbox is >@bb<\n";
	return if ((scalar @bb == 0) || ($bb[2] - $bb[0] == 0));
	my $needsize = $this->columnWidth(1);
	$this->columnWidth(0, $bb[2] - $bb[0] - $needsize);

	# invoke any given callback
	my @args = ( $this );
	$this->Callback(-sizecmd_cb => @args);
}


#---------------------------------------------
# CALLBACK: update the view (type 'normal')
#           means Data-Column is invisible
#---------------------------------------------
sub map_cb
{
	# Parameters
	my $this = shift;
	$this->setup_view();
}

#---------------------------------------------
# ADD-ON: get Item and / or ItemData
# returns a scalar(first only) or an array
#---------------------------------------------
sub get_item
{
	# Parameters
	my ($this, $path) = @_;

	# get all information	
	my @items_out = $this->_get_item(3, $path);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub get_item_text
{
	# Parameters
	my ($this, $path) = @_;

	# get all information	
	my @items_out = $this->_get_item(1, $path);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub get_item_value
{
	# Parameters
	my ($this, $path) = @_;

	# get all information	
	my @items_out = $this->_get_item(2, $path);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub _get_item
{
	# Parameters
	my ($this, $mode, $path) = @_;

	# Locals
	my (@items_out);

	if ($mode & 1) {
		push @items_out, $this->itemCget($path, 0, '-text');
	}
	if ($mode & 2) {
		push @items_out,  $this->infoData($path);
	}
	return wantarray ? @items_out : $items_out[0];
}

#---------------------------------------------
# ADD-ON: Get Current Selected Text AND/OR associated Data
#---------------------------------------------
sub getcurselection
{
	# Parameters
	my $this = shift;

	# get all information	
	my @items_out = $this->_getcurselection(3);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub getcurselection_text
{
	# Parameters
	my $this = shift;

	# get all information	
	my @items_out = $this->_getcurselection(1);

	return wantarray ? @items_out : $items_out[0];
}
#---------------------------------------------
sub getcurselection_value
{
	# Parameters
	my $this = shift;

	# get all information	
	my @items_out = $this->_getcurselection(2);

	return wantarray ? @items_out : $items_out[0];
}

#---------------------------------------------
sub _getcurselection
{
	# Parameters
	my ($this) = shift;
	my ($mode) = shift;

	# Locals
	my (@items_out, @selitems, $path);

	# get index information	
	@selitems = $this->infoSelection;
	foreach $path (@selitems) {
		if ($mode & 1) {
			push @items_out, $this->itemCget($path, 0, '-text' );
		}
		if ($mode & 2) {
			push @items_out, $this->infoData($path);
		}
	}
	return wantarray ? @items_out : $items_out[0];
}


########################################################################
1;
__END__

=cut

=head1 NAME

Tk::DataHList - A HList widget with a visible/hidden data column

=head1 SYNOPSIS

    use Tk;
    use Tk::DataHList

    my $mw = MainWindow->new();


    #my $listbox = $mw->DataHList(
    my $listbox = $mw->Scrolled('DataHList', 
        -scrollbars          => 'e',
        -cursor              => 'right_ptr',
        -relief              => 'sunken',
        -borderwidth         => '2',
        -width               => '10',  # columns
        -height              => '15',  # lines
        -background          => 'orange',
        -selectmode          => 'single',
		-sizecmd             => \&size_cb,
		#new options
        -viewtype            => 'withdata',
		-datastyle           => $datastyle;
		-databackground      => 'skyblue',
        -numeric_primary_sort   => '0',
        -numeric_secondary_sort => '1',
    )->pack;

	
    Tk::MainLoop;
	
    sub add_data
    {
        # 1) insert a complete array with texts and data, keys become 'visible' entry,
        # values are stored as data and are shown in transient column.
        $listbox->add($key, -data => 'i02',
					-itemtype => 'imagetext',
					-text => 'Dummy',
					-image => $xpms{dummy},
					#-datastyle => $datastyle,
		);
   }
   sub size_cb
   {
      print "we have resized\n";
   }

=head1 DESCRIPTION

A HList derived widget that offers several add-on functions like in-place-editing,
sorting, reordering and inserting/retrieving of item text & data, 
suitable for perl Tk800.x (developed with Tk800.024).

You can insert item-texts or item-text/-value pair/s into the DataHList widget with
the standard-like  B<add()> method .
The B<delete> removes visible list-items as well as the associated data.

B<get_item()>, B<get_item_text()>, B<get_item_value()> retrieve either a scalar or lists,
depending on the context it was invoked. In scalar mode they return
the first item only (/first item-text/-text/-value/). In list context
they return the text AND the belonging data.

B<getcurselection()>, B<getcurselection_text()>, B<getcurselection_value()>,
and B<getcurselection_index()> also retrieve either a scalar or a list,
depending on the context but for the currently selected listitem. 
For scalar mode same rule applies as for B<get_item>.

B<reverse()> reverses the whole list and all item values.

B<sort()> sorts the whole list alphanumerical and reorders and all items and belonging

B<Configure()> understands the new editing-related options B<-editactivationEvent>,
B<-editfinishonLeave>, B<-posteditcommand> and B<-validate>. The first one allows to
specify an event descriptor for the activation of the Editing features, 
the second enables the automatic finish-edit feature if the mouse leaves the edit-area,
The others may be used to specify callbacks: One for postprocessing after editing is
finished and the other one, which can be used to perform validation operations
during editing.

B<viewtype()> might be invoked directly or via I<configure> to switch between
'withdata' or 'normal' listbox view.

If the Listbox has the input focus the key 'B<Control-Key-[>' makes the data-list
visible and 'B<Control-Key-]>' hides it.

=head1 METHODS

=over 4

=item B<add()>

'add($path, <options> )' inserts item text & data
in the list. Inserting without '-data' just uses the HList the with a 
default 'undef'-data per item.


=item B<delete()>

'delete(what [, $path] )' removes item text & data
from/to the specified positions in the list
-acts as the default delete().


=item B<get_item()>

'get_item($path )' retrieves item text & data
from/to the specified positions in the list. 
B<get_item_text()> and B<get_item_value()> work analogous but for
texts/values only


=item B<getcurselection()>

'getcurselection()' retrieves item-text & -data from the current selected
position in the list.
B<getcurselection_text()>, B<getcurselection_value()> and B<getcurselection_index()>
work anlogous but for texts/values only


=item B<reverse()>

'reverse()' reverses the whole list and all belonging item values.


=item B<sort()>

'sort($direction)' sorts the whole list alphanumerical. The direction parameter
may be 'I<ascending>' or 'I<descending>'


=item B<viewtype()>

'viewtype()' switches the listbox' visible area between the 'normal' view and
the extended one 'withdata', that shows a second column with all the belonging data.

=back


=head1 OPTIONS


=over 4

=item B<viewtype()>

'-viewtype()' switches the listbox' visible area between the 'normal' view and
the extended one 'withdata', that shows a second column with all the belonging data.

=item B<datastyle()>

'-datastyle()' allows to specify an ItemStyle for the data column (see Tk::ItemStyle for details).

=item B<databackground()>

'-databackground()' allows to specify just a different background color for the data column.
Note that it still uses the build-in ItemStyle (beside bg-color) for the data column.

=item B<numeric_primary_sort()>

'-numeric_primary_sort()' allows to enable numeric ordering for the internal sort()
function (numeric on primary keys / first column).

=item B<numeric_secondary_sort()>

'-numeric_secondary_sort()' allows to enable numeric ordering for the internal sort()
function (numeric on secondary keys / second column).

=back

=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V1.1  (C) May 2005

=cut

###
### EOF
###

