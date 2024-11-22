functor

import
    OS
    System
export
    'getPort': SpawnAgent
define
    PokemOzList
    Surround
    TrainersList
    TurnNr
    Hp
    SHp
    Trainers
    Timer
    GCPort
    State

    % Feel free to modify it as much as you want to build your own agents :) !

    % Helper => returns an integer between [0, N]
    fun {GetRandInt N} {OS.rand} mod N end

    % Helper => returns the id of first trainer or (if no trainer is in range) pokemoz in range
    fun {TrainerAround Surround}
        case Surround of nil then
            ~1
        [] trainer(Id) | _ then
            Id
        [] _ | Rest then
            {TrainerAround Rest}
        end
    end
        
    fun {PokemozAround Surround}
        case Surround of nil then
            ~1
        [] pokemoz(Id) | _ then
            Id
        [] _ | Rest then
            {TrainerAround Rest}
        end
    end

    fun {ClosestTarget type}
        if type == pokemoz then
            {GetRandInt {Length State.PokemOzList}-1}
        else
            {GetRandInt {Length State.TrainersList}-1}
        end
    end
    
    
    fun {FindPath TargetX TargetY}
        if {Abs (State.id.x-TargetX)} < {Abs (State.id.y-TargetY)} then
            if (State.id.x-TargetX) < 0 then
                'east'
            else 'west'
            end
        else
            if {State.id.y-TargetY} < 0 then
                'south'
            else 'north'
            end
        end
    end
    
     

    % TODO: Complete this concurrent functional agent
    fun {Agent State}
        %TODO: add functions to handle messages
        fun {AttackFailed Msg}
            {Agent {AdjoinAt State state {AdjoinAt State.state action {Adjoin State.state.action 1}}}}
        end

        fun {CannotMove Msg}
            {Agent {AdjoinAt State state {AdjoinAt State.state action {Adjoin State.state.action 1}}}}
        end
        fun {AttackSuccessful Msg}
            case State.state 
            of aggressive() then {Agent {AdjoinAt State state {Adjoin State.state aggressive(Hp:State.state.Hp timer:0 action:1)}}}
            else {Agent {AdjoinAt State state {AdjoinAt State.state action {Adjoin State.state.action 1}}}}
            end
        end

        fun {MapInfo Msg}
            {Agent State}
        end
        fun {NewTurn X}
            {Agent State}
        end
    in
            % {Send State.gcport moveTo(State.id 'east')}
            % {Send State.gcport moveTo(State.id 'south')}
            % {Send State.gcport moveTo(State.id 'west')}
            % {Delay 1000}
            % {Send State.gcport attack(1 5 2)}
            % {Delay 1000}
            % {Send State.gcport moveTo(1 'north')}
            % {Delay 1000}
            % {Send State.gcport beamAttack(1 10 'east')}
            % {Delay 1000}
            % {Send State.gcport moveTo(1 'north')}
            % {Delay 1000}
            % {Send State.gcport moveTo(1 'east')}
            % {Delay 1000}
            % {Send State.gcport attack(1 5 2)}
            % {Delay 1000}
            % {Send State.gcport moveTo(1 'east')}
            % {Delay 1000}
            % {Send State.gcport moveTo(1 'north')}
            % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                %TODO: add messages
                'CannotMove':CannotMove
                'newturn':NewTurn
                'attackSuccessful(Victim)':AttackSuccessful
                'attackFailed':Beam
                'beaaam':Beam
                'mapInfo':MapInfo
                'newTurn':NewTurn
            )
        in
            if {HasFeature Interface Dispatch} then
                {Interface.Dispatch Msg}
            else
                % {System.show log('Unhandled message' Dispatch)}
                {Agent State}
            end
        end
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        {Handler Upcoming {Instance Msg}}
    end

    fun {SpawnAgent init(Id GCPort Map)}
        Stream
        Port = {NewPort Stream}

        Instance = {Agent state(
            'id': Id
            'turnnr': TurnNr
            'map': Map
            'surround': Surround
            'pokemozlist': PokemOzList
            'trainerslist': TrainersList
            'gcport': GCPort
            'state': neutral(Hp:10 SHp:10 action:0)
        )}
    in 
        % {Send GCPort test()}
        thread
        if Id==2 then {Send GCPort attack(Id 5 1)}{Send GCPort moveTo(Id 'north')}{Send GCPort moveTo(Id 'east')}{Send GCPort attack(Id 3 2)}{Send GCPort attack(Id 3 2)}
            
    elseif Id==1 then {Send GCPort attack(Id 1 2)}{Send GCPort moveTo(Id 'west')} {Send GCPort attack(Id 2 2)}{Send GCPort attack(Id 3 2)}{Send GCPort attack(Id 4 2)} 
        {Send GCPort attack(Id 1 2)} {Send GCPort attack(Id 2 2)} else skip end
end
        % for I in 1..10 do
        %     {Send GCPort moveTo(Id 'west')}
        %     {Send GCPort moveTo(Id 'south')}
        %     {Send GCPort moveTo(Id 'east')}
        %     {Send GCPort moveTo(Id 'north')}
        % end
        thread {Handler Stream Instance} end
        Port
    end
end
