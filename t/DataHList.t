# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use Test;
use strict;

BEGIN { plan tests => 18 };

my $widget;

eval { require Tk; };
ok($@, "", "loading Tk module");

my $mw;
eval {$mw = Tk::MainWindow->new();};
ok($@, "", "can't create MainWindow");

ok(Tk::Exists($mw), 1, "MainWindow creation failed");

#--------------------------------------------------------------
my $class = 'DataHList';
my $foo = 'i01';
my $bar = 'DummyProject';
my $result;
my %bar = ('txt1' => 'data1', 'txt2' => 'data2', 'txt3' => 'data3' );
#--------------------------------------------------------------
print "Testing $class\n";

eval "require Tk::$class;";
ok($@, "", "Error loading Tk::$class");

eval { $widget = $mw->$class(); };
ok($@, "", "can't create $class widget");
skip($@, Tk::Exists($widget), 1, "$class instance does not exist");

if (Tk::Exists($widget)) {
    eval { $widget->pack; };

    ok ($@, "", "Can't pack a $class widget");
    eval { $mw->update; };
    ok ($@, "", "Error during 'update' for $class widget");
	#------------------------------------------------------------------
	my $style = $mw->ItemStyle ('text' ,
							-anchor => 'e',
							#-justify => 'right',
							#-wraplength => '6',
							-background => 'yellow',	);
    eval { $widget->configure( -datastyle => $style ); };
    ok ($@, "", "Error: can't configure  '-datastyle' for $class widget");
    eval { $widget->configure( -sizecmd => \&test_cb ); };
    ok ($@, "", "Error: can't configure  '-sizecmd' for $class widget");
	#
    eval { $widget->add('i01', -data => 'i01',
				-itemtype => 'text',
				-text => 'DummyProject',
				#-image => $xpms{project_icon},
				-datastyle => $style); };
    ok ($@, "", "Error: can't add text/data for $class widget");
    eval { $widget->add('i02', -data => 'i02',
				-itemtype => 'text',
				-text => 'DummyTask',
				#-image => $xpms{task_icon},
				-datastyle => $style,); };
    ok ($@, "", "Error: can't add text/data for $class widget");
    eval { $result = $widget->get_item('i01'); };
	ok($result, $bar, "can't get scalar from $class widget");
    $result = $widget->get_item_value('i01');
	ok($result, $foo, "$result, $bar can't get data of scalar from $class widget");
	
	# here we need some more tests
	#...
	
	#------------------------------------------------------------------

    eval { my @dummy = $widget->configure; };
    ok ($@, "", "Error: configure list for $class");
    eval { $mw->update; };
    ok ($@, "", "Error: 'update' after configure for $class widget");

    eval { $widget->destroy; };
    ok($@, "", "can't destroy $class widget");
    ok(!Tk::Exists($widget), 1, "$class: widget not really destroyed");
} else  { 
    for (1..5) { skip (1,1,1, "skipped because widget couldn't be created"); }
}
sub test_cb
{
	print "test_cb called with [@_], \$foo = >$foo<\n";
}

1;
