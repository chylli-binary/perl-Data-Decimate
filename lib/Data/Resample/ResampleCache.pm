package Data::Resample::ResampleCache;

use strict;
use warnings;

use 5.010;
use Moose;

use Scalar::Util qw( blessed );
use Sereal::Encoder;
use Sereal::Decoder;

extends 'Data::Resample';

=head1 SUBROUTINES/METHODS

=head2 resample_cache_backfill

=cut

sub resample_cache_backfill {
    my ($self, $args) = @_;

    my $symbol   = $args->{symbol}   // '';
    my $ticks    = $args->{ticks}    // [];
    my $backtest = $args->{backtest} // 0;

    my $key = $self->_make_key($symbol, 0);

    if (not $backtest) {
        foreach my $tick (@$ticks) {
            $self->_update($self->redis_write, $key, $tick->{epoch}, $self->encoder->encode($tick));
        }
    }

    return $self->_resample({
        symbol   => $symbol,
        ticks    => $ticks,
        backtest => $backtest,
    });
}

=head2 resample_cache_get

=cut

sub resample_cache_get {
    my ($self, $args) = @_;

    my $which = $args->{symbol}      // '';
    my $start = $args->{start_epoch} // 0;
    my $end   = $args->{end_epoch}   // time;

    my $redis = $self->redis_read;

    my @res;
    my $key = $self->_make_key($which, 1);

    @res = map { $self->decoder->decode($_) } @{$redis->zrangebyscore($key, $start, $end)};

    my @sorted = sort { $a->{epoch} <=> $b->{epoch} } @res;

    return \@sorted;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
