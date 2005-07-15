#!/usr/bin/perl -w
#
# ptkbl - A Perl/Tk GUI based Perl-script editor with improved column mode editing and syntax highlighting. Based on Tomi Parviainen's T-Pad
#
# Usage: see Perl documentation in pod format (perldoc)
#
use strict;
use Tk;

{   ###########################################################################
    package TextBlockHighlight;
    ###########################################################################

    use vars qw($VERSION %FUNC %FLOW %OPER);
    $VERSION = '4.04';

    my @FUNC = qw/AUTOLOAD BEGIN CHECK CORE DESTROY END INIT abs accept alarm atan2 bind binmode bless caller chdir chmod chomp chop chown chr chroot close closedir cmp connect cos crypt dbmclose dbmopen defined delete die dump each endgrent endhostent endnetent endprotoent endpwent endservent eof eval exec exists exit exp fcntl fileno flock fork format formline getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname gethostent getlogin getnetbyaddr getnetbyname getnetent getpeername getpgrp getppid getpriority getprotobyname getprotobynumber getprotoent getpwent getpwnam getpwuid getservbyname getservbyport getservent getsockname getsockopt glob gmtime grep hex index int ioctl join keys kill lc lcfirst length link listen localtime log lock lstat map mkdir msgctl msgget msgrcv msgsnd new oct open opendir ord pack pipe pop pos print printf prototype push quotemeta rand read readdir readline readlink readpipe recv ref rename reset reverse rewinddir rindex rmdir scalar seek seekdir select semctl semget semop send setgrent sethostent setnetent setpgrp setpriority setprotoent setpwent setservent setsockopt shift shmctl shmget shmread shmwrite shutdown sin sleep socket socketpair sort splice split sprintf sqrt srand stat study substr symlink syscall sysopen sysread sysseek system syswrite tell telldir tie tied time times truncate uc ucfirst umask undef unlink unpack unshift untie utime values vec wait waitpid wantarray warn write/;
    my @FLOW = qw/continue do else elsif for foreach goto if last local my next our no package redo require return sub unless until use while __DATA__ __END__ __FILE__ __LINE__ __PACKAGE__/;
    my @OPER = qw/and eq ge gt le lt m ne not or q qq qr qw qx s tr y xor x/;

    # Build lookup tables
    @FUNC{@FUNC} = (1) x @FUNC; undef @FUNC;
    @FLOW{@FLOW} = (1) x @FLOW; undef @FLOW;
    @OPER{@OPER} = (1) x @OPER; undef @OPER;

    use Tk qw(Ev);
    use AutoLoader;

    # Set @TextBlockHighlight::ISA = ('Tk::TextUndo')
    use base qw(Tk::TextUndo);


    Construct Tk::Widget 'TextBlockHighlight';

    sub ClassInit {
        my ($class, $mw) = @_;
        $class->SUPER::ClassInit($mw);
        $mw->bind($class, '<Control-o>', \&main::openDialog);
        $mw->bind($class, '<Control-n>', [\&main::addPage, 'Untitled']);
        $mw->bind($class, '<Control-s>', [\&main::saveDialog, 's']);
        $mw->bind($class, '<Control-r>', \&main::runScript);
#        $mw->bind($class, '<F1>', \&main::commandHelp);
#         $mw->bind($class, '<F4>', \&main::ColumnSelect);
        return $class;
    }

    sub InitObject {
        my ($w, $args) = @_;
        $w->SUPER::InitObject($args);
        $w->tagConfigure('FUNC', -foreground => '#FF0000');
        $w->tagConfigure('FLOW', -foreground => '#0000FF');
        $w->tagConfigure('OPER', -foreground => '#FF8200');
        $w->tagConfigure('STRG', -foreground => '#848284');
        $w->tagConfigure('CMNT', -foreground => '#008284');
        $w->tagConfigure('BLUE', -background => '#E0F4F4');
        $w->tagConfigure('MTCH', -background => '#FFFF00');
        # Default: font family courier, size 10
        $w->configure(-font => $w->fontCreate(qw/-family courier -size 14 /),-selectbackground =>'#ffff33', -wrap => 'none');
        $w->{CALLBACK} = undef;
        $w->{CHANGES} = 0;
        $w->{LINE} = 0;
    }

    sub Button1 {
        my $w = shift;
        $w->SUPER::Button1(@_);
        &{$w->{CALLBACK}} if ( defined $w->{CALLBACK} );
    }
    sub SelectTo {
        my $w = shift;
        $w->SUPER::SelectTo(@_);
  my @ranges = $w->tagRanges('sel');
  
  my $range_total = @ranges;
#  print "RT:", $range_total,"\n";
 # this only makes sense if there is one selected block
  unless ($range_total==2)
  {
  $w->bell;
  return;
  }

 my $selection_start_index = shift(@ranges);
 my $selection_end_index = shift(@ranges);

 my ($start_line, $start_column) = split(/\./, $selection_start_index);
 my ($end_line,   $end_column)   = split(/\./, $selection_end_index);

 # correct indices for tabs
 my $string;
 $string = $w->get($start_line.'.0', $start_line.'.0 lineend');
 $string = substr($string, 0, $start_column);
# $string = expand($string);
 my $tab_start_column = length($string);

 $string = $w->get($end_line.'.0', $end_line.'.0 lineend');
 $string = substr($string, 0, $end_column);
# $string = expand($string);
 my $tab_end_column = length($string);

 my $length = $tab_end_column - $tab_start_column; 

 $selection_start_index = $start_line . '.' . $tab_start_column;
 $selection_end_index   = $end_line   . '.' . $tab_end_column;

 # clear the clipboard
# $w->clipboardClear;
 my ($clipstring, $startstring, $endstring);
# my $padded_string = ' 'x$tab_end_column;
#$tw->configure(-selectbackground =>'#ffff00');
 my $line = 1;
  $w->tagRemove('BLUE' ,  '1.0', 'end');

 for($line = $start_line; $line <= $end_line; $line++)
 {
#  print '--',$line,' ', $tab_start_column,' ', $tab_end_column, "\n";
  $w->tagAdd('BLUE' ,  $line.'.'. $tab_start_column,  $line.'.'. $tab_end_column);
 }
 #$tw->configure(-selectbackground =>'#ffff33');
 
}


    sub see {
        my $w = shift;
        $w->SUPER::see(@_);
        &{$w->{CALLBACK}} if ( defined $w->{CALLBACK} );
    }

    sub unselectAll {
       my $w = shift;
        $w->tagRemove('BLUE' ,  '1.0', 'end');
        $w->SUPER::unselectAll(@_);
        
    }
    
    sub KeySelect {
        my $w = shift;
        $w->tagRemove('BLUE' ,  '1.0', 'end');
        $w->SUPER::KeySelect(@_);
        
    }

    # Set/Get the amount of changes
    sub numberChangesExt {
        my ($w, $changes) = @_;
        if ( @_ > 1 ) {
            $w->{CHANGES} = $changes;
        }
        return $w->{CHANGES};
    }

    # Register callback function and call it immediately
    sub positionChangedCallback {
        my ($w, $callback) = @_;
        &{$w->{CALLBACK} = $callback};
    }

    sub insert {
        my $w = shift;
        my ($s_line) = split(/\./, $w->index('insert'));
        $w->SUPER::insert(@_);
        my ($e_line) = split(/\./, $w->index('insert'));
        highlight($w, $s_line, $e_line);
        &{$w->{CALLBACK}} if ( defined $w->{CALLBACK} );
    }

    # Insert text without highlight
    sub insertWHL {
        my $w = shift;
        $w->SUPER::insert(@_);
    }

    # Background highlight
    sub backgroundHL {
        my ($w, $l) = @_;
        my ($end) = split(/\./, $w->index('end'));
        $w->{LINE} = $end unless ( $w->{LINE} );
        # 'cut/delete' correction if needed
        if ( $w->{LINE} != $end ) {
            $l -= ($w->{LINE} - $end);
            if ( $l < 0 ) { $l = 0 }
            $w->{LINE} = $end;
        }
        highlight($w, $l, $l+50 > $end ? $end-1 : $l+50);
        if ( $l+50 < $end ) {
            $w->after(50, [\&backgroundHL, $w, $l+50+1]);
        }
        else { $w->{LINE} = 0 }
    }

    sub insertTab {
        my ($w) = @_;
        my $pos = (split(/\./, $w->index('insert')))[1];
        # Insert spaces instead of tabs
        $w->Insert(' ' x (4-($pos%4)));
        $w->focus;
        &{$w->{CALLBACK}} if ( defined $w->{CALLBACK} );
        $w->break;
    }

    sub delete {
        my $w = shift;
        $w->SUPER::delete(@_);
        my ($line) = split(/\./, $w->index('insert'));
        highlight($w, $line, $line);
    }

    sub InsertKeypress {
        my $w = shift;
        $w->SUPER::InsertKeypress(@_);

        # Easy things easy...
        if ( $_[0] =~ /[([{<"']/ ) {
            $w->SUPER::InsertKeypress(')') if ( $_[0] eq '(' );
            $w->SUPER::InsertKeypress(']') if ( $_[0] eq '[' );
            $w->SUPER::InsertKeypress('}') if ( $_[0] eq '{' );
            $w->SUPER::InsertKeypress('>') if ( $_[0] eq '<' );
            $w->SUPER::InsertKeypress('"') if ( $_[0] eq '"' );
            $w->SUPER::InsertKeypress("'") if ( $_[0] eq "'" );
            $w->SetCursor('insert-1c');
        }

        my ($line) = split(/\./, $w->index('insert'));
        highlight($w, $line, $line);
        &{$w->{CALLBACK}} if ( defined $w->{CALLBACK} );
    }

    sub highlight {
        my ($w, $s_line, $e_line) = @_;

        # Remove tags from current area
        foreach ( qw/FUNC FLOW OPER STRG CMNT/ ) {
            $w->tagRemove($_, $s_line.'.0', $e_line.'.end');
        }

        foreach my $ln($s_line .. $e_line) {
            my $line = $w->get($ln.'.0', $ln.'.end');
            # Highlight: strings
            while ( $line =~ /("             # Start at double quote
                                  (?:        # For grouping only
                                      \\.|   # Backslash with any character
                                      [^"\\] # Must not be able to find
                                  )*         # Zero or more sets of those
                              "|
                              (?<!\$)        # Prevent $' match
                              '              # Start at single quote
                                  (?:        # For grouping only
                                      \\.|   # Backslash with any character
                                      [^'\\] # Must not be able to find
                                  )*         # Zero or more sets of those
                              ')/gx ) {
                $w->tagAdd('STRG', $ln.'.'.(pos($line)-length($1)),
                           $ln.'.'.pos($line));
            }
            # Highlight: comments
            while ( $line =~ /(?<!       # Lookbehind for neither
                                  [\$\\] # $ nor \
                              )\#        # Start of the comment
                             /gx ) {
                next if ( $w->tagNames($ln.'.'.(pos($line)-1)) &&
                          $w->tagNames($ln.'.'.(pos($line)-1)) eq 'STRG' );
                $w->tagAdd('CMNT', $ln.'.'.(pos($line)-1), $ln.'.end');
                $line = $w->get($ln.'.0', $ln.'.'.(pos($line)-1));
                last;
            }
            # Highlight: functions, flow control words and operators,
            # do not highlight hashes, arrays or scalars
            while ( $line =~ /(?<!              # Lookbehind for neither
                                  [\%\@\$])     # %, @, nor $
                                      \b        # Match a word boundary
                                          (\w+) # Match a "word"
                                      \b        # Match a word boundary
                             /gx ) {
                if ( $OPER{$1} ) {
                    $w->tagAdd('OPER', $ln.'.'.(pos($line)-length($1)),
                               $ln.'.'.pos($line));
                }
                elsif ( $FLOW{$1} ) {
                    $w->tagAdd('FLOW', $ln.'.'.(pos($line)-length($1)),
                               $ln.'.'.pos($line));
                }
                elsif ( $FUNC{$1} || $1 =~ /^(\d+)$/ ) {
                    $w->tagAdd('FUNC', $ln.'.'.(pos($line)-length($1)),
                               $ln.'.'.pos($line));
                }
            }
        }
    }
} # END - package TextBlockHighlight

###############################################################################
package main;
###############################################################################

use File::Find;
use File::Basename;
use Tk::HList;
use Tk::Dialog;
use Tk::ROText;
use Tk::Balloon;
use Tk::DropSite;
use Tk::NoteBook;
use Tk::Adjuster;

# Seed the random number generator
BEGIN { srand() if $] < 5.004 }

my $rcfile = "$ENV{'HOME'}/.ptkblrc";
my $initialdir= "$ENV{'HOME'}/";

# List of supported file patterns
my @filetypes = (
    ['texts',     '.txt',  'TEXT'],
    ['all',     '*',  'TEXT']);

# Create main window and return window handle
my $mw = MainWindow->new(-title => 'ptkbl Column mode commands: F1: copy F2: cut F3: paste ');

# Manage window manager protocol
$mw->protocol('WM_DELETE_WINDOW' => \&exitCommand);

# Add menubar
$mw->configure(-menu =>
my $menubar = $mw->Menu(-tearoff => $Tk::platform eq 'unix'));

# Add 'File' entry to the menu
my $file = $menubar->cascade(qw/-label File -underline 0 -menuitems/ =>
    [
        [command => '~New',         -accelerator => 'Ctrl+N',
                                    -command => [\&addPage, 'Untitled']],
        [command => '~Open...',     -accelerator => 'Ctrl+O',
                                    -command => \&openDialog],
        [command => '~Close',       -command => \&closeCommand,
                                    -state   => 'disabled'],
        '',
        [command => '~Save',        -accelerator => 'Ctrl+S',
                                    -command => [\&saveDialog, 's']],
        [command => 'Save ~As...',  -command => [\&saveDialog, 'a']],
        '',
        [command => 'E~xit',        -command => \&exitCommand],
    ], -tearoff => $Tk::platform eq 'unix');

# Add 'Edit' entry to the menu
my $edit = $menubar->cascade(qw/-label Edit -underline 0 -menuitems/ =>
    [
        [command => '~Undo',        -accelerator => 'Ctrl+Z',
                                    -command => [\&menuCommands, 'eu']],
        [command => '~Redo',        -accelerator => 'Ctrl+Y',
                                    -command => [\&menuCommands, 'er']],
        '',
        [command => 'Cu~t',         -accelerator => 'Ctrl+X',
                                    -command => [\&menuCommands, 'et']],
        [command => 'C~opy',        -accelerator => 'Ctrl+C',
                                    -command => [\&menuCommands, 'eo']],
        [command => 'P~aste',       -accelerator => 'Ctrl+V',
                                    -command => [\&menuCommands, 'ea']],
        '',
        [command => 'Select A~ll',  -command => [\&menuCommands, 'el']],
        [command => 'Unsele~ct All',-command => [\&menuCommands, 'ec']],
    ], -tearoff => $Tk::platform eq 'unix');

# Add 'Misc' entry to the menu
my $misc = $menubar->cascade(qw/-label Misc -underline 0 -menuitems/ =>
    [
        [command => '~Properties...',       -command => \&propertiesDialog],
        [Checkbutton => 'CR~LF Conversion', -variable => \my $crlf],
        [command => '~Configure',        
                                    -command => \&configure],
    ], -tearoff => $Tk::platform eq 'unix');

# Add 'Help' entry to the menu
my $help = $menubar->cascade(qw/-label Help -underline 0 -menuitems/ =>
    [
        [command => '~About...',    -command => \&aboutDialog],
    ], -tearoff => $Tk::platform eq 'unix');

# Add NoteBook metaphor
my $nb = $mw->NoteBook();

# Accept drops from an external application
$nb->DropSite(-dropcommand => \&handleDND,
              -droptypes   => ($^O eq 'MSWin32' or ($^O eq 'cygwin' and
                              $Tk::platform eq 'MSWin32')) ? ['Win32'] :
                              [qw/KDE XDND Sun/]);

my ($tw, $cmdHelp, %pageName);
# Accept ASCII text file or file which does not exist
foreach ( @ARGV ) {
    if ( (-e $_ && -T _) || !-e _ ) {
        addPage($_);
    }
}

# Add default page if there are no pages in notebook metaphor
unless ( keys %pageName ) {
    addPage('Untitled');
}

# Show filename over the 'pageName' using balloons
my ($balloon, $msg) = $mw->Balloon(-state => 'balloon',
                                   -balloonposition => 'mouse');
$balloon->attach($nb, -balloonmsg => \$msg,
                -motioncommand => sub {
                    my ($nb, $x, $y) = @_;
                    # Adjust screen to widget coordinates
                    $x -= $nb->rootx;
                    $y -= $nb->rooty;
                    my $name = $nb->identify($x, $y);
                    if ( defined $name ) {
                        $msg = 'File name: '.$pageName{$name}->FileName();
                        0; # Don't cancel the balloon
                    } else { 1 } # Cancel the balloon
                });

# Add status bar to the bottom of the screen
my $fr = $mw->Frame->pack(qw/-side bottom -fill x/);
$fr->Label(-textvariable => \my $st)->pack(qw/-side left/);
$fr->Label(-textvariable => \my $clk)->pack(qw/-side right/);
updateClock();


my $prev_cmd;
$nb->pack(qw/-side top -expand 1 -fill both/);

my $dialog = $mw->DialogBox( -title   => "Ptkbl Configure",
                            -buttons => [ "Configure", "Cancel" ]			    
                           );

$dialog->add("Label", -text => "Initial Directory for Open File")->pack();
my $entry21 = $dialog->add("Entry", -textvariable => \$initialdir, -width => 55,-background => '#fffff9')->pack();


ReadConfiguration();

# Start the GUI and eventloop
MainLoop;


sub ReadConfiguration {
if ($^O eq 'MSWin32')
   {$rcfile = "./ptkblrc";}
if(open(F,"<".$rcfile)){
  my $sor;
  while($sor = <F>){
   chop($sor);
   if ($sor eq "[InitialDir]"){
     $sor = <F>;
     chop($sor);
     $initialdir = $sor;
   } 
  }
  close(F);
 } else {
  print "Can't open ".$rcfile,"\n";;
 }
}


sub configure{
#print "ccc\n";
    my $button;
    my $done = 0;
    my ($oldinitialdir);
    $oldinitialdir = $initialdir;
    
    do {    
        # show the dialog
        $button = $dialog->Show;

        # act based on what button they pushed
        if ($button eq "Configure") {
#             print "you entered:",$WorkDirName, $MbrolaSound, $txt2phoProc, "\n";
            if($oldinitialdir ne $initialdir){ 
	     WriteConfiguration();
	     }
	     $done = 1;
	 } else {
#           $fr =  "Configuration aborted";
           $done = 1;
        }
    } until $done;

}


sub WriteConfiguration {
if(open(F,">".$rcfile)){
  print F "[InitialDir]\n";
  print F $initialdir,"\n";
  print F "\n";
  close(F);
 }
}



# Create modal 'About' dialog
sub aboutDialog {
    my $popup = $mw->Dialog(
        -popover        => $mw,
        -title          => 'About ptkbl',
        -bitmap         => 'Tk',
        -default_button => 'OK',
        -buttons        => ['OK'],
        -text           => "ptkbl\nVersion 4.04 - 05-June-2005\n\n".
                           "Copyright (C) Eleonora\n".
                           "http://www.cpan.org/scripts/\n\n".
                           "Perl Version $]\n".
                           "Tk Version $Tk::VERSION",
        );
    $popup->resizable('no', 'no');
    $popup->Show();
}

# Add page to notebook metaphor
sub addPage {
    shift if UNIVERSAL::isa($_[0], 'TextBlockHighlight');
    my $pageName = shift;

    # If the page exist, raise the old page and return
    foreach ( keys %pageName ) {
        if ( ($pageName{$_})->FileName() eq $pageName &&
              $pageName ne 'Untitled' ) {
            return $nb->raise($_);
        }
    }

    # Add new page with 'random' name to the notebook
    my $name = rand();
    my $page = $nb->add($name,
                        -label => basename($pageName),
                        -raisecmd => \&pageChanged);

    # Create a widget with attached scrollbar(s)
    $tw = $page->Scrolled(qw/TextBlockHighlight
                            -spacing2 1 -spacing3 1
                            -scrollbars ose -background white
                            -borderwidth 2 -width 80 -height 25
                            -relief sunken/)->pack(qw/-expand 1 -fill both/);

    $tw->FileName($pageName);
    $pageName{$name} = $tw;
    $tw->bind('<FocusIn>', sub {
        $tw->tagRemove('MTCH', '0.0', 'end');
    });

    # Change popup menu to contain 'Edit' menu entry
    $tw->menu($edit->menu);
    mouseWheel($tw);

    if ( keys %pageName > 1 ) {
        # Enable 'File->Close' menu entry
        $file->cget(-menu)->entryconfigure(2 + ($Tk::platform eq 'unix'),
                                           -state => 'normal');
    }

    $nb->raise($name);

    # Write data to the new page. File 'Untitled' can
    # be used as a template for new script files!
    writeData($pageName);

    # Register callback function
    $tw->positionChangedCallback(\&updateStatus);
}

# Remove page and disable 'Close' menu item when needed
sub closeCommand {
    if ( confirmCh() ) {
        delete $pageName{$nb->raised()};
        $nb->delete($nb->raised());
    }
    if ( keys %pageName == 1 ) {
        # Disable 'File->Close' menu entry
        $file->cget(-menu)->entryconfigure(2 + ($Tk::platform eq 'unix'),
                                           -state => 'disabled');
    }
}

# Confirm the changes user has made before proceeding
sub confirmCh {
    if ( $nb->pagecget($nb->raised(), -label) =~ /\*/ ) {
        my $answer = $tw->Dialog(

                        -popover => $mw, -text => 'Save changes to '.
                         basename($tw->FileName()), -bitmap => 'warning',
                        -title => 'ptkbl', -default_button => 'Yes',
                        -buttons => [qw/Yes No Cancel/])->Show;
        if ( $answer eq 'Yes' ) {
            saveDialog('s');
            return 0 if ( $nb->pagecget($nb->raised(), -label) =~ /\*/ ||
                          $tw->FileName() eq 'Untitled' );
        }
        elsif ( $answer eq 'Cancel' ) {
            return 0;
        }
    }
    return 1;
}


# Close all pages and quit ptkbl
sub exitCommand {
    while ( (my $pages = keys %pageName) > 0 ) {
        closeCommand();
        # Check if the user has pressed 'Cancel' button
        last if ( keys %pageName == $pages );
    }
    exit if ( keys %pageName == 0 );
}


# Goto line, which has been passed as a parameter
sub gotoLine {
    my $line = shift;
    $tw->markSet('insert', "$line.0");
    $tw->see('insert');
    $tw->markUnset('insert');
    $tw->tagRemove('MTCH', '0.0', 'end');
    $tw->tagAdd('MTCH', "$line.0", "$line.0 lineend + 1c");
}

# Get the filename of the drop and add new page to the notebook metaphor
sub handleDND {
    my ($sel, $filename) = shift;

    # In case of an error, do the SelectionGet in an eval block
    eval {
        if ( $^O eq 'MSWin32' ) {
            $filename = $tw->SelectionGet(-selection => $sel, 'STRING');
        }
        else {
            $filename = $tw->SelectionGet(-selection => $sel, 'FILE_NAME');
        }
    };
    if ( defined $filename && -T $filename ) {
        addPage($filename);
    }
}

# Handle different menu accelerator commands, which cannot be handled
# directly in menu entry (because of the tight bind of $tw)
sub menuCommands {
    my $cmd = shift;
    if    ( $cmd eq 'eu' ) { $tw->undo }
    elsif ( $cmd eq 'er' ) { $tw->redo }
    elsif ( $cmd eq 'et' ) { $tw->clipboardCut }
    elsif ( $cmd eq 'eo' ) { $tw->clipboardCopy }
    elsif ( $cmd eq 'ea' ) { $tw->clipboardPaste }
    elsif ( $cmd eq 'el' ) { $tw->selectAll }
    elsif ( $cmd eq 'ec' ) { $tw->unselectAll }
}

# Support for mouse wheel
sub mouseWheel {
    my $w = shift;

    # Windows support
    $w->bind('<MouseWheel>', [sub {
        $_[0]->yviewScroll(-($_[1]/120)*3, 'units');
    }, Tk::Ev('D')]);

    # UNIX support
    if ( $Tk::platform eq 'unix' ) {
        $w->bind('<4>', sub {
            $_[0]->yviewScroll(-3, 'units') unless $Tk::strictMotif;
        });
        $w->bind('<5>', sub {
            $_[0]->yviewScroll( 3, 'units') unless $Tk::strictMotif;
        });
    }
}

# Pop up a dialog box for the user to select a file to open
sub openDialog {
    my $filename = $mw->getOpenFile(-filetypes => \@filetypes, -initialdir => $initialdir);
    if ( defined $filename and $filename ne '' ) {
        addPage($filename)
    }
}

# Notebook page has changed, change the focus to the new page
# and initialise status bar to reflect page data
sub pageChanged {
    $tw = $pageName{$nb->raised()};
    $tw->focus if ( !defined $mw->focusCurrent ||
                    UNIVERSAL::isa($mw->focusCurrent, 'MainWindow') ||
                    UNIVERSAL::isa($mw->focusCurrent, 'TextBlockHighlight') );

    # Disable/Enable 'Misc->Properties' menu entry
    if ( -e $tw->FileName() ) {
        $misc->cget(-menu)->entryconfigure(0 + ($Tk::platform eq 'unix'),
                                           -state => 'active');
    }
    else {
        $misc->cget(-menu)->entryconfigure(0 + ($Tk::platform eq 'unix'),
                                           -state => 'disabled');
    }
    updateStatus();
}


# Create modal 'Properties' dialog
sub propertiesDialog {
    # Return if the file does not exist
    return unless ( -e $tw->FileName() );
    my $popup = $mw->Dialog(
        -popover => $mw,
        -title   => 'Source File Properties',
        -bitmap  => 'info',
        -default_button => 'OK',
        -buttons => ['OK'],
        -text    => "Name:\t".basename($tw->FileName()).
                "\nSize:\t".(stat($tw->FileName()))[7]." Bytes\n".
                "Saved:\t".localtime((stat($tw->FileName()))[9])."\n".
                "Mode:\t".sprintf("%04o", 07777&(stat($tw->FileName()))[2])
        );
    $popup->resizable('no', 'no');
    $popup->Show();
}

# Run the script (currently with blocking the caller)
sub runScript {
    shift if UNIVERSAL::isa($_[0], 'TextBlockHighlight');
    my $params = $_[0] ? $_[0] : '';

    if ( confirmCh() && -e $tw->FileName() ) {
        system("$^X \"".$tw->FileName()."\" $params");
    }
}

# Pop up a dialog box for the user to select a file to save
sub saveDialog {
    my $filename;
    shift if UNIVERSAL::isa($_[0], 'TextBlockHighlight');

    if ( $_[0] eq 's' && $tw->FileName() ne 'Untitled' ) {
        $filename = $tw->FileName();
    }
    else {
        $filename = $mw->getSaveFile(-filetypes => \@filetypes,
	                             -initialdir => $initialdir,
                                     -initialfile => basename($tw->FileName()),
                                     -defaultextension => '.pl');
    }

    if ( defined $filename and $filename ne '' ) {
        if ( open(FILE, ">$filename") ) {
            # Write file to disk (change cursor to reflect this operation)
            $mw->Busy(-recurse => 1);
	    my $sor;
	    my $i;
	    my $betu;
            my ($e_line) = split(/\./, $tw->index('end - 1 char'));
            foreach ( 1 .. $e_line-1 ) {
	    #
	    # remove blank padding
	    #
	        $sor = $tw->get($_.'.0', $_.'.0 + 1 lines');
		while(length($sor)){
		 $betu = chop($sor);
		 if(($betu ne "\r") &&  ($betu ne "\n") && ($betu ne " ")){
		    $sor .= $betu;
		    last;
		 }   
		}
                print FILE $sor."\n";
            }
	    #
	    # remove blank padding
	    #
 	        $sor = $tw->get($e_line.'.0', 'end - 1 char');
		while(length($sor)){
		 $betu = chop($sor);
		 if(($betu ne "\r") &&  ($betu ne "\n") && ($betu ne " ")){
		    $sor .= $betu;
		    last;
		 }   
		}
            print FILE $sor."\n";
            $mw->Unbusy;
            close(FILE) or print "$!";
            $tw->FileName($filename);
            $nb->pageconfigure($nb->raised(), -label => basename($filename));
            $tw->numberChangesExt($tw->numberChanges);
            # Ensure 'File->Properties' menu entry is active
            $misc->cget(-menu)->entryconfigure(0 + ($Tk::platform eq 'unix'),
                                               -state => 'active');
        }
        else {
            my $msg = "File may be ReadOnly, or open for write by ".
                      "another application! Use 'Save As' to save ".
                      "as a different name.";
            $mw->Dialog(-popover => $mw, -text => $msg,
                        -bitmap => 'warning',
                        -title => 'Cannot save file',
                        -buttons => ['OK'])->Show;
        }
    }
}

# Update clock (without seconds) every minute
sub updateClock {
    ($clk = scalar localtime) =~ s/(\d+:\d+):(\d+)\s/$1 /;
    $mw->after((60-$2)*1000, \&updateClock);
}

# Update the statusbar
sub updateStatus {
    my ($cln, $ccol) = split(/\./, $tw->index('insert'));
    my ($lln) = split(/\./, $tw->index('end'));
    $st = "Line $cln (".($lln-1).'), Column '.($ccol+1);

    my $title = $nb->pagecget($nb->raised(), -label);
    # Check do we need to add/remove '*' from title
    if ( $tw->numberChanges != $tw->numberChangesExt() ) {
        if ( $title !~ /\*/ ) {
            $title .= '*';
            $nb->pageconfigure($nb->raised(), -label => $title);
        }
    }
    elsif ( $title =~ /\*/ ) {
        $title =~ s/\*//;
        $nb->pageconfigure($nb->raised(), -label => $title);
    }
}

# Write data to text widget via read buffer
sub writeData {
    my $filename = $tw->FileName();

    if ( -e $filename ) {
        open(FILE, $filename) or die "$!";
        my $read_buffer;
        while ( <FILE> ) {
            s/\x0D?\x0A/\n/ if ( $crlf );
	    chop($_);
	    my $i = length($_);
	    #
	    # pad lines with blanks for column editing
	    #
	    while($i < 80){
	      $_ .= ' ';
	      $i++;
	    }
	    $_ .= "\n";
            $read_buffer .= $_;
	      
            if ( ($.%100) == 0 ) {
                $tw->insertWHL('end', $read_buffer);
                undef $read_buffer;
            }
        }
        if ( $read_buffer ) {
            $tw->insertWHL('end', $read_buffer);
        }
        close(FILE) or die "$!";
    }

    $tw->ResetUndo;
    # Set cursor to the first line of text widget
    $tw->insertWHL('0.0');
    $tw->backgroundHL(1);
}


__END__

=head1 NAME

ptkbl - A Perl/Tk GUI based Perl-script editor with improved column mode and syntax highlighting

=head1 SYNOPSIS

perl B<ptkbl.pl> [I<file(s)-to-edit>]

=head1 DESCRIPTION

ptkbl is a Perl/Tk GUI based text editor with improved column mode editing  and perl syntax highlighting. ptkbl supports syntax highlight for *.pl, *.pm, *.cgi  and .txt files. 
=head1 README

A Perl/Tk GUI based Perl-script editor with with improved column mode editing and perl syntax highlighting (*.pl, *.pm and *.cgi. *.txt, *). ptkbl runs under Windows, Unix and Linux.  Based on Tomi Parviainen's T-Pad.

=head1 PREREQUISITES

This script requires the C<Tk> a graphical user interface toolkit module for Perl.

=head1 AUTHOR

Eleonora <F<eleonora45_at_gmx_dot_net>>

=head1 COPYRIGHT

Copyright (c) 2005, Eleonora. All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=pod SCRIPT CATEGORIES

Win32
Win32/Utilities

=cut
