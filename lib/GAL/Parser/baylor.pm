package GAL::Parser::baylor;

use strict;
use vars qw($VERSION);


$VERSION = '0.01';
use base qw(GAL::Parser);

=head1 NAME

GAL::Parser::baylor - <One line description of module's purpose here>

=head1 VERSION

This document describes GAL::Parser::baylor version 0.01

=head1 SYNOPSIS

     use GAL::Parser::baylor;

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
     Usage   : GAL::Parser::baylor->new();
     Function: Creates a GAL::Parser::baylor object;
     Returns : A GAL::Parser::baylor object
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
	my @valid_attributes = qw(); # Set valid class attributes here.
	$self->set_attributes($args, @valid_attributes);
	######################################################################

	# The columns are:
	#
	# BCM_local_SNP_ID -- unique ID for referring to the SNPs ahead of
	# submission to dbSNP (we can talk about what and when to submit to
	# dbSNP).
	#
	# chromosome --  (self explanatory)
	#
	# coordinate -- (self explanatory)
	#
	# reference_allele -- plus strand reference base
	#
	# variant_allele -- plus strand variant base
	#
	# match_status -- a Y, N or "." if a dbSNP allele, Y if the variant
	# matches the dbSNP allele, or N if it doesn't; a "." if it's a novel
	# SNP.
	#
	# rs# -- the rsid if dbSNP, "novel" otherwise.
	#
	# alternate_allele -- usually a "." (surrogate for null). A, C, T or G
	# if a third allele is seen in the reads at the given position, it's
	# listed here.  I'm don't expect you to dis play 3d allele
	# information.
	#
	# variant_count -- number of reads in which variant allele was
	# seen. Can be 1 variants matching dbSNP alleles ("Y" in match_status
	# column), must be 2 for novel alleles, for dbSNP positions that don't
	# match the dbSNP alleles ("N" in match_status column) or for dbSNP
	# positions where there is an alternate allele.
	#
	# alternate_allele_count -- number of reads in which an
	# alternate_allele is seen. Generally these are seen in only one read
	# and are probably errors, and should not be mentioned. I n some rare
	# instances (134 times), both the variant allele and the alternate
	# allele are seen multiple times.
	#
	# total_coverage -- the total number of reads at a given SNP position.
	#
	# "genotype" -- "het" if the reference allele is seen at least
	# once. "." (null) if not. These are the sites that are confidently
	# heterozygotes. The others provisionally homozygote s, and in cases
	# where the coverage is deep enough probably they are.

	$self->fields([qw(id chromosome coordinate reference_allele
			  variant_allele match_status rsid alternate_allele
			  variant_count alternate_allele_count
			  total_coverage genotype)]);
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

	# $record is a hash reference keyed to the fields of the
	# incoming data These key names are set in the $self->fields
	# call in _initialize_args above

	# Fill in the first 8 columns for GFF3
	# See http://www.sequenceontology.org/resources/gff3.html for details.

	# id chromosome coordinate reference_allele variant_allele
	# match_status rsid alternate_allele variant_count
	# alternate_allele_count total_coverage genotype

	my $id         = $record->{id};
	my $seqid      = $record->{chromosome};
	my $source     = 'Baylor';

	my $type       = 'SNP';
	my $start      = $record->{coordinate};
	my $end        = $record->{coordinate};
	my $score      = '.';
	my $strand     = '.';
	my $phase      = '.';

	# Create the attributes hash

	# Assign the reference and variant allele sequences:
	# reference_allele=A;
	# variant_allele=G;
	my $reference_allele = $record->{reference_allele};
	my @variant_alleles;
	push @variant_alleles, $record->{variant_allele};

	# Assign the reference and variant allele read counts:
	# reference_reads=A:7;
	# variant_reads=G:8;
	my $reference_reads = $reference_allele . ":" . ($record->{total_coverage} -
							 $record->{variant_count}  -
							 $record->{alternate_count});
	my @variant_reads;
	push @variant_reads, ($record->{variant_allele}   . ":" . $record->{variant_count});

	if ($record->{alternate_allele} ne '.') {
		push @variant_reads, ($record->{alternate_allele} . ":" . $record->{alternate_allele_count});
		push @variant_alleles, $record->{alternate_allele};
	}

	# If we have reference_reads then push that allele to the variants
	if ($record->{total_coverage} - $record->{variant_count}  - $record->{alternate_count} > 0) {
		push @variant_reads, $reference_reads;
		push @variant_alleles, $reference_allele;
	}

	# Assign the total number of reads covering this position:
	# total_reads=16;
	my $total_reads = $record->{total_coverage};

	# Assign the genotype:
	# genotype=homozygous;
	my $their_genotype = $record->{genotype} eq 'het' ? 'heterozygous' : undef;
	my $our_genotype   = $self->get_genotype($reference_allele, \@variant_alleles);

	# Assign the probability that the genotype call is correct:
	# genotype_probability=0.667;

	# Any quality score given for this variant should be assigned
	# to $score above (column 6 in GFF3).  Here you can assign a
	# name for the type of score or algorithm used to calculate
	# the sscore (e.g. phred_like, clcbio, illumina).
	# score_type=baylor;

	# Create the attribute hash reference.  Note that all values
	# are array references - even those that could only ever have
	# one value.  This is for consistency in the interface to
	# Features.pm and it's subclasses.  Suggested keys include
	# (from the GFF3 spec), but are not limited to: ID, Name,
	# Alias, Parent, Target, Gap, Derives_from, Note, Dbxref and
	# Ontology_term. Note that attribute names are case
	# sensitive. "Parent" is not the same as "parent". All
	# attributes that begin with an uppercase letter are reserved
	# for later use. Attributes that begin with a lowercase letter
	# can be used freely by applications.

	# For sequence_alteration features the suggested keys include:
	# reference_allele, variant_allele, reference_reads, variant_reads
	# total_reads, genotype, genotype_probability and score type.
	my $attributes = {reference_allele => [$reference_allele],
			  variant_allele   => \@variant_alleles,
			  genotype         => [$our_genotype],
			  ID               => [$id],
			  reference_reads  => [$reference_reads],
			  variant_reads    => \@variant_reads,
			  total_reads      => [$total_reads],
			  genotype         => [$our_genotype],
			 };

	my $feature_data = {id         => $id,
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

<GAL::Parser::baylor> requires no configuration files or environment variables.

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