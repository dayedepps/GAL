#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::RealBin/../../lib";
use lib "$FindBin::RealBin/../../lib/cpan";
use GAL::Run;

chdir $FindBin::Bin;
my $path = "$FindBin::Bin/..";

my $tool = GAL::Run->new(path => $path,
			 command => 'gal_validate_proteins');

################################################################################
# Testing that gal_validate_proteins compiles and returns usage statement
################################################################################

ok(! $tool->run(cl_args => '--help'), 'gal_validate_proteins complies');
like($tool->get_stdout, qr/Synopsis/, 'gal_validate_proteins prints usage statement');

################################################################################
# Testing that gal_validate_proteins does something else
################################################################################

my @cl_args = ('data/refseq_chr22.trim.gff3',
	       'data/hg18_chr22.fa',
	        );

ok(! $tool->run(cl_args => \@cl_args), 'gal_validate_proteins runs');
ok($tool->get_stdout =~ /NM_138338:mRNA\s+VALID/,
   'gal_validate_proteins has the correct output');
ok($tool->get_stdout =~ /NM_012324:mRNA\s+INVALID\s+MADRAEMFSLSTFHSLSPPGCRPPQDISLEE/,
   'gal_validate_proteins has the correct output');

$tool->clean_up;
done_testing();

################################################################################
################################# Ways to Test #################################
################################################################################

__END__

# Various other ways to say "ok"
ok($this eq $that, $test_name);

is  ($this, $that,    $test_name);
isnt($this, $that,    $test_name);

# Rather than print STDERR "# here's what went wrong\n"
diag("here's what went wrong");

like  ($this, qr/that/, $test_name);
unlike($this, qr/that/, $test_name);

cmp_ok($this, '==', $that, $test_name);

is_deeply($complex_structure1, $complex_structure2, $test_name);

can_ok($module, @methods);
isa_ok($object, $class);

pass($test_name);
fail($test_name);

BAIL_OUT($why);
