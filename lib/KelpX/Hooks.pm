package KelpX::Hooks;

our $VERSION = '1.01';

use strict;
use warnings;
use Exporter qw(import);
use Carp qw(croak);

our @EXPORT = qw(
	hook
);

sub hook
{
	my ($subname, $decorator) = @_;
	my $package = caller;

	croak "Hooking build() method is forbidden"
		if $subname eq "build";

	my $build_method = $package->can("build");
	croak "Can't hook $subname: no build() method in $package"
		unless defined $build_method;

	no strict 'refs';
	no warnings 'redefine';

	*{"${package}::build"} = sub {
		my ($self) = @_;

		my $hooked_method = $package->can($subname);
		croak "Trying to hook $subname, which doesn't exist"
			unless defined $hooked_method;

		*{"${package}::$subname"} = sub {
			my ($kelp, @args) = @_;

			return wantarray ?
				$decorator->($hooked_method, $kelp, @args) :
				scalar $decorator->($hooked_method, $kelp, @args);
		};

		goto $build_method;
	};
	return;
}


1;
__END__

=head1 NAME

KelpX::Hooks - Override any method in your Kelp application

=head1 SYNOPSIS

	# in your Kelp application
	use KelpX::Hooks;

	# and then...
	hook "template" => sub {
		return "No templates for you!";
	};

=head1 DESCRIPTION

This module allows you to override methods in your Kelp application class. The provided C<hook> method can be compared to Moose's C<around>, and it mimics its interface. The difference is in how and when the replacement of the actual method occurs.

The problem here is that Kelp's modules are modifying the symbol table for the module at the runtime, which makes common attempts to change their methods` behavior futile. You can't override them, you can't change them with method modifiers, you can only replace them with different methods.

This module fights the symbol table magic with more symbol table magic. It will replace any method with your anonymous subroutine after the application is built and all the modules have been loaded.

=head2 EXPORT

=head3 hook

	hook "sub_name" => sub {
		my ($original_sub, $self, @arguments) = @_;

		# your code, preferably do this at some point:
		return $self->$original_sub(@arguments);
	};

Allows you to provide your own subroutine in place of the one specified. The first argument is the subroutine that's being replaced. It won't be run at all unless you call it explicitly.

Please note that Kelp::Less is not supported.

=head1 CAVEATS

This module works by replacing the build method in symbol tables. Because of this, you cannot hook the build method itself.

=head1 SEE ALSO

L<Kelp>, L<Moose::Manual::MethodModifiers>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
