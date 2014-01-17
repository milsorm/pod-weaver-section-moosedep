package Pod::Weaver::Section::MooseConsumes 0.01;
# ABSTRACT: Add section with consumed roles based on Moose class based on package filename

use strict;
use warnings;

use Class::Inspector;
use Module::Load;
use Moose;
use Module::Metadata;

with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

sub weave_section {
    my ( $self, $doc, $input ) = @_;

    my $filename = $input->{filename};

    return if $filename !~ m{\.pm$};

	my $info = Module::Metadata->new_from_file( $filename );
    my $module = $info->name();
	
	return unless $module;

    unless ( Class::Inspector->loaded( $module ) ) {
        eval { local @INC = ( 'lib', @INC ); Module::Load::load $module };
        print "$@" if $@;    #warn
    }

    return unless $module->can('meta');

    my @roles = sort
		grep { $_ ne $module } $self->_get_roles($module);

    return unless @roles;

    my @pod = (
        Command->new( {
			command => 'over',
			content => 4
		} ),
        (
            map {
                Command->new( {
					command => 'item',
					content => "* L<$_>",
				} ),
            } @roles
        ),
        Command->new( {
			command => 'back',
			content => ''
        } )
    );

    push @{ $doc->children },
	    Nested->new( {
            type     => 'command',
            command  => 'head1',
            content  => 'CONSUMES',
            children => \@pod
        } );
}

sub _get_roles {
    my ( $self, $module ) = @_;

    my @roles = map { $_->name } eval { $module->meta->calculate_all_roles };
    print "Possibly harmless: $@" if $@;

    return @roles;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
