package Pod::Weaver::Section::MooseConsumes;
# ABSTRACT: Add Pod::Weaver section with consumed roles (what I am implementing) based on Moose OOP framework

our $VERSION = '0.02';

=head1 SYNOPSIS

In your C<weaver.ini>:

	[MooseConsumes]

=head1 DESCRIPTION

This L<Pod::Weaver> section plugin creates a "CONSUMES" section in your POD
which contains a list of your class's parent classes. It accomplishes this
by loading all classes and inspecting it through Moose framework.

It can work with all Moose classes based on filename (also outside of distribution
tree). All classes (*.pm files) in your distribution's lib directory will be loaded.
POD is changed only for files which actually consumes some roles.

=head1 SEE ALSO

L<Pod::Weaver::Section::MooseExtends> 
L<Pod::Weaver::Section::Consumes> 
L<Moose>
L<Moose::Role>

=cut

use strict;
use warnings;

use Class::Inspector;
use Module::Load;
use Moose;
use Module::Metadata;

with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';

# This is implicit method of plugin for extending Pod::Weaver, cannot be called directly
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

# Private method for extracting consumed roles through meta/superclasses
sub _get_roles {
    my ( $self, $module ) = @_;

    my @roles = map { $_->name } eval { $module->meta->calculate_all_roles };
    print "Possibly harmless: $@" if $@;

    return @roles;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
