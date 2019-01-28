# --
# Copyright (C) (2013) (Denny Bresch) (dennybresch@gmail.com) (https://github.com/dennybresch)
# Copyright (C) 2012-2019 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketQuickDelete;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for (qw(ParamObject DBObject LayoutObject LogObject ConfigObject QueueObject TimeObject TicketObject)) {
        if ( !$Self->{$_} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $_!" );
        }
    }
    # get config of frontend module
    $Self->{Config} = $Self->{ConfigObject}->Get("Ticket::Frontend::$Self->{Action}");


    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Self->{TicketID} ) {
        return $Self->{LayoutObject}->ErrorScreen(
            Message => 'No TicketID is given!',
            Comment => 'Please contact the admin.',
        );
    }

    # check permissions
    my $Access = $Self->{TicketObject}->TicketPermission(
        Type     => $Self->{Config}->{Permission},
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID}
    );

    # error screen, don't show ticket
    if ( !$Access ) {
        return $Self->{LayoutObject}->NoPermission(
            Message    => "You need $Self->{Config}->{Permission} permissions!",
            WithHeader => 'yes',
        );
    }

    my $Queue = $Self->{Config}->{Queue};
    if ($Queue) {
        my $Success = $Self->{TicketObject}->TicketQueueSet(
            Queue  => $Queue,
            TicketID => $Self->{TicketID},
            UserID   => $Self->{UserID},
        );
        if ($Success) {
            $Self->{TicketObject}->TicketLockSet(
                TicketID => $Self->{TicketID},
                Lock     => 'unlock',
                UserID   => $Self->{UserID},
            );
        }
    }
    return $Self->{LayoutObject}->Redirect( OP => $Self->{LastScreenOverview} );
}

1;
