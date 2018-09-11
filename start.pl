#!/usr/bin/perl

use Template;
use YAML::Syck;
use File::Spec::Functions 'catfile';
use File::Copy qw( copy );
use File::Path qw( make_path );
use Term::ANSIColor qw( :constants );
use Data::Dumper;
use Pod::Usage;
use Modern::Perl;

=head1 USAGE

 $ perl start.pl ~/path/to/plugin/dir/

This script takes one argument, the path to the directory where you want to
develop your plugin. You will need to run this command twice, to get the full
benefit of the starter.

=cut

pod2usage( -exitval => 0 ) unless $ARGV[0];

=head1 STAGE 1

First time you run this script, a sample config file will be copied to the
destination directory. Open the copied config and edit it to your liking. The
file has plenty of comments to guide you along.

=cut

# Get the directory specified by the user
my $dir = $ARGV[0];

# Make sure the directory exists
unless ( -d $dir ) {
    die RED, "You need to create the directory at $dir", RESET, "\n";
}

# Copy over the sample config file
my $config_file = catfile( $dir, 'config.yaml');
unless ( -f $config_file ) {
    copy 'files/config.yaml', $config_file;
    say GREEN, "Created $config_file. Please edit it before re-running this script.", RESET;
    exit;
} else {
    say GREEN, "Config file $config_file exists.", RESET;
    # Proceed to create the skeleton files
}

=head1 STAGE 2

The second time you run this script, it will read the edited config file in the
destination directory and start to add skeleton files there, based on the
choices you made in the config file. This should give you a good starting point
for developing your plugin.

Files that are generated:

=cut

my $config = LoadFile( $config_file );

# say Dumper $config;

# Configure Template Toolkit
my $ttconfig = {
    INCLUDE_PATH => './templates',
    ENCODING => 'utf8',
};
# create Template object
my $tt2 = Template->new( $ttconfig ) || die Template->error(), "\n";

=head2 README

A very basic README in POD or markdown format is added.

=cut

# Check that we have a valid format
die RED, "readme_format must be pod or md", RESET, "\n", unless ( $config->{'readme_format'} eq 'pod' || $config->{'readme_format'} eq 'md' );

# Determine the filename
my $readme_file = catfile( $dir, "README.$config->{'readme_format'}" );

# Check if the file already exists
if ( -e $readme_file && $config->{'devel_mode'} == 0 ) {
    say RED, "$readme_file exists", RESET;
    exit;
}

# Create the file
$tt2->process( "README.$config->{'readme_format'}.tt", $config, $readme_file ) || die RED, $tt2->error(), RESET;
say GREEN, "Created $readme_file", RESET;

=head2 Module

A skeleton module is added, with the capabilities (and location) specified in the config file.

=cut

# Make sure we have the full namespace
$config->{'full_namespace'} = "Koha::Plugin::$config->{'namespace'}";

# Split the namespace into parts
my @ns = split /::/, $config->{'full_namespace'};

# Determine the path of the directory we want to create
my $full_path = catfile( $dir, @ns );

# Create the path
make_path( $full_path );
say GREEN, "Created $full_path", RESET;

# Now create the module
my $module_file = "$full_path.pm";
$tt2->process( "module.tt", $config, $module_file ) || die RED, $tt2->error(), RESET;
say GREEN, "Created $module_file", RESET;

__END__
