functor

import
    OS
    System
export
    'getPort': SpawnAgent
define

    % Feel free to modify it as much as you want to build your own agents :) !

    % Helper => returns an integer between [0, N]
    fun {GetRandInt N} {OS.rand} mod N end
    
    % TODO: Complete this concurrent functional agent
    fun {Agent State}
        %TODO: add functions to handle messages
        fun {Dummy Msg}
            {Agent State}
        end
        fun {CannotMove Msg}
            {Agent State}
        end
        fun {NewTurn Msg}
            {Agent State}
        end
        fun {AttackSuccessful Msg}
            {Agent State}
        end
        fun {Beam Msg}
            {Agent State}
        end
        fun {MapInfo Msg}
            {System.show 'MapInfo'}
            {Agent State}
        end
    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                %TODO: add messages
                'dummy': Dummy
                'CannotMove':CannotMove
                'newturn':NewTurn
                'attackSuccessful(Victim)':AttackSuccessful
                'attackFailed':Dummy
                'beaaam':Beam
                'mapInfo':MapInfo
            )
        in
            if {HasFeature Interface Dispatch} then
                {Interface.Dispatch Msg}
            else
                % {System.show log('Unhandle message' Dispatch)}
                {Agent State}
            end
        end
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        case Msg of Dummy then {Handler Upcoming Instance}
        [] Attack then {Attack Msg}
        [] MoveSelf then {MoveSelf Msg}
        [] LookMap then {LookMap Msg}
            else {Handler Upcoming Instance}
        end
    end

    fun {SpawnAgent init(Id GCPort Map)}
        Stream
        Port = {NewPort Stream}

        Instance = {Agent state(
            'id': Id
            'gcport': GCPort
        )}
    in
        thread {Handler Stream Instance} end
        Port
    end
end
