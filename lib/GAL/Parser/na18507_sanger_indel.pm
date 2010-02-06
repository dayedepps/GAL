package GAL::Parser::illumina_sanger_indel;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';
use base qw(GAL::Parser);

=head1 NAME

GAL::Parser::illumina_sanger_indel - <One line description of module's purpose here>

=head1 VERSION

This document describes GAL::Parser::illumina_sanger_indel version 0.01

=head1 SYNOPSIS

     use GAL::Parser::illumina_sanger_indel;

=for author to fill in:
     Brief code example(s) here showing commonest usage(s).
     This section will be as far as many users bother reading
     so make it as educational and exemplary as possible.

=head1 DESCRIPTION

=for author to fill in:
     Write a full description of the module and its features here.
     Use subsections (=head2, =head3) as appropriate.

=head1 METHODS

=cut

#-----------------------------------------------------------------------------

=head2 new

     Title   : new
     Usage   : GAL::Parser::illumina_sanger_indel->new();
     Function: Creates a illumina_sanger_indel object;
     Returns : A illumina_sanger_indel object
     Args    :

=cut

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	return $self;
}

#-----------------------------------------------------------------------------

sub _initialize_args {
	my ($self, @args) = @_;

	######################################################################
	# This block of code handels class attributes.  Use the
	# @valid_attributes below to define the valid attributes for
	# this class.  You must have identically named get/set methods
	# for each attribute.  Leave the rest of this block alone!
	######################################################################
	my $args = $self->SUPER::_initialize_args(@args);
	my @valid_attributes = qw(); # Set valid class attributes here
	$self->set_attributes($args, @valid_attributes);
	######################################################################

	# give lalbes for the fields in your file.
	# note parser will automatically ignore lines begining with #

	$self->fields([qw(chr location allele_text score)]);
}

#-----------------------------------------------------------------------------

=head2 parse_record

 Title   : parse_record
 Usage   : $a = $self->parse_record();
 Function: Parse the data from a record.
 Returns : A hash ref needed by Feature.pm to create a Feature object
 Args    : A hash ref of fields that this sub can understand (In this case GFF3).

=cut

sub parse_record {
	my ($self, $record) = @_;

	# 1       709353  */+ATAAT        16
	# 1       741363  */+AT   45
	# 1       757983  */-TTG  13
	# 1       768166  +CT/+CT 373
	# 1       770921  -C/*    723
	# 1       776933  */-AG   114

	# $self->fields([qw(chr pos ref_base con_base con_qual read_depth ave_hits_elsewhere)]);

	my @variant_alleles = grep {$_ ne '*'} split m|/|, $record->{allele_text};

	# Ignore records that are compound heterozygous.
	return undef if (scalar @variant_alleles == 2 && $variant_alleles[0] ne $variant_alleles[1]);

	my ($genotype, $reference_allele, $type, $start, $end);

	$genotype = scalar @variant_alleles == 1 ? 'heterozygous' : 'homozygous';

	for my $variant_allele (@variant_alleles) {
		if ($variant_allele =~ /^-/) {
			$type = 'nucleotide_deletion';
			($reference_allele = $variant_allele) =~ s/^-//;
			$variant_allele = '-';
			$start = $record->{location};
			$end   = $record->{location} + length($reference_allele) - 1;
		}
		else {
			$type = 'nucleotide_insertion';
			$variant_allele =~ s/^\+//;
			$reference_allele = '-';
			$start = $record->{location};
			$end   = $record->{location};
		}
	}

	my $id         = join ':', ('NA18507_Sanger', 'chr' . $record->{chr}, $type,  $start);
	my $seqid      = 'chr' . $record->{chr};
	my $source     = 'NA18507_Sanger';
	my $score      = $record->{score};
	my $strand     = '+';
	my $phase      = '.';

	my $attributes = {Reference_seq => [$reference_allele],
			  Variant_seq   => \@variant_alleles,
			  Genotype      => [$genotype],
			  ID            => [$id],
			 };

	my $feature_data = {feature_id => $id,
			    seqid      => $seqid,
			    source     => $source,
			    type       => $type,
			    start      => $start,
			    end        => $end,
			    score      => $score,
			    strand     => $strand,
			    phase      => $phase,
			    attributes => $attributes,
			   };

	return $feature_data;
}
#-----------------------------------------------------------------------------

=head2 foo

 Title   : foo
 Usage   : $a = $self->foo();
 Function: Get/Set the value of foo.
 Returns : The value of foo.
 Args    : A value to set foo to.

=cut

sub foo {
	my ($self, $value) = @_;
	$self->{foo} = $value if defined $value;
	return $self->{foo};
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

=for author to fill in:
     List every single error and warning message that the module can
     generate (even the ones that will "never happen"), with a full
     explanation of each problem, one or more likely causes, and any
     suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back

=head1 CONFIGURATION AND ENVIRONMENT

<GAL::Parser::illumina_sanger_indel> requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to:
barry.moore@genetics.utah.edu

=head1 AUTHOR

Barry Moore <barry.moore@genetics.utah.edu>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Barry Moore <barry.moore@genetics.utah.edu>.  All rights reserved.

    This module is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;