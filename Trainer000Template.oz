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

        fun {NewTurn Msg}
            local UpdatedState in
                case State.state
                of neutral(Hp SHp _) then
                    UpdatedState = neutral(Hp:Msg.trainer.hp SHp:Msg.trainer.hp action:0)
                [] scared(Hp Timer _) then
                    UpdatedState = scared(Hp:Msg.trainer.hp Timer:Timer action:0)
                [] attacked(Hp _) then
                    UpdatedState = attacked(Hp:Msg.trainer.hp action:0)
                [] aggressive(Hp Timer _) then
                    UpdatedState = aggressive(Hp:Msg.trainer.hp Timer:Timer action:0)
                end
                {Agent {Adjoin State state(turnnr:Msg.TurnNr surround:Msg.Surround pokemozlist:Msg.PokemOzList state:UpdatedState)} 0}
                {TrainerDo}
            end
        end
        

        fun {AttackSuccessful Msg}
            case State.state 
            of aggressive() then {Agent {AdjoinAt State state {Adjoin State.state aggressive(Hp:State.state.Hp timer:0 action:1)}}}
            else {Agent {AdjoinAt State state {AdjoinAt State.state action {Adjoin State.state.action 1}}}}
            end
        end

        fun {MapInfo Msg}
            {System.show 'MapInfo'}
            case State.state 
            of attacked() then {Agent {Adjoin State state(map:Msg.Map trainerslist:Msg.Trainers state:{Adjoin State.state attacked(action:1)})} 0}
            [] scared() then {Agent {Adjoin State state(map:Msg.Map trainerslist:Msg.Trainers state:{Adjoin State.state scared(action:1)})} 0}
            [] aggressive() then {Agent {Adjoin State state(map:Msg.Map trainerslist:Msg.Trainers state:{Adjoin State.state aggressive(action:1)})} 0}
            end
            {TrainerBecome}
        end

        fun {TrainerBecome}
            local NewState in
                case State.state
                of neutral(Hp SHp Action) then
                    if Hp < 4 then
                        NewState = scared(Hp:Hp Timer:0 action:Action)
                    elseif SHp > Hp then
                        NewState = attacked(Hp:Hp action:Action)
                    else
                        NewState = State.state
                    end
                [] scared(Hp Timer Action) then
                    if Hp > 3 then
                        NewState = neutral(Hp:Hp SHp:Hp action:Action)
                    elseif Timer == 0 then
                        NewState = scared(Hp:Hp Timer:3 action:Action)
                    else
                        NewState = scared(Hp:Hp Timer:Timer~1 action:Action)
                    end
                [] attacked(Hp Action) then
                    if Action == 1 then
                        NewState = neutral(Hp:Hp SHp:Hp action:0)
                    else
                        NewState = aggressive(Hp:Hp Timer:10-{GetRandInt 5} action:Action)
                    end
                [] aggressive(Hp Timer Action) then
                    if Hp > 13 then
                        NewState = State.state
                    elseif Timer =< 0 then
                        NewState = neutral(Hp:Hp SHp:Hp action:Action)
                    else
                        NewState = aggressive(Hp:Hp Timer:Timer~1 action:Action)
                    end
                end
                {Agent {Adjoin State state(NewState)}}
            end
        end
        
        

        fun {TrainerDo}
            if State.state.action == 1 then raise error('Multiple actions in a single turn is not allowed') end
            elseif State.turnnr == 100 then {Send lookMap(State.id.id State.turnnr)}
            else 
                if {TrainerAround State.surround} \= ~1 then
                    {Send attack(State.id.id State.turnnr {TrainerAround State.surround})}
                else
                    case State.state
                    of neutral() then
                        if {PokemozAround State.surround} \= ~1 then 
                            {Send  attack(State.id.id State.turnnr {PokemozAround State.surround})}
                        else
                            local TargetId TargetX TargetY in
                                TargetId = {ClosestTarget pokemoz}
                                for pokemoz in State.PokemOzList do
                                    if pokemoz.id == TargetId then
                                        TargetX = pokemoz.x
                                        TargetY = pokemoz.y
                                    end
                                end
                                {Send  moveTo(State.id.id {FindPath TargetX TargetY})}
                            end
                        end
                    [] scared() then
                        if State.state.timer == 0 then 
                            {Send  lookMap(State.id.id State.turnnr)}
                        elseif {PokemozAround State.surround} \= ~1 then
                            {Send  attack(State.id.id State.turnnr {PokemozAround State.surround})}
                        else
                            local TargetId TargetX TargetY in
                                TargetId = {ClosestTarget pokemoz}
                                for pokemoz in State.PokemOzList do
                                    if pokemoz.id == TargetId then
                                        TargetX = pokemoz.x
                                        TargetY = pokemoz.y
                                    end
                                end
                                {Send  moveTo(State.id.id {FindPath TargetX TargetY})}
                            end
                        end
                    [] attacked() then
                        {Send  lookMap(State.id.id State.turnnr)}
                    [] aggressive() then
                        local TargetId=0 TargetX=0 TargetY=0 in
                            TargetId = {ClosestTarget trainer}
                            for trainer in State.TrainersList do
                                if trainer.id == TargetId then
                                    TargetX = trainer.x
                                    TargetY = trainer.y
                                end
                            end
                            if coord(TargetX TargetY) \= coord(State.id.x State.id.y) then
                                {Send  moveTo(State.id.id {FindPath TargetX TargetY})}
                            else
                                {Send  lookMap(State.id.id State.turnnr)}
                            end
                        end
                    end
                end
            end
        end
    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                %TODO: add messages
                'CannotMove':CannotMove
                'newturn':NewTurn
                'attackSuccessful(Victim)':AttackSuccessful
                'attackFailed':AttackFailed
                'beaaam': AttackSuccessful
                'mapInfo':MapInfo
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
        thread {Handler Stream Instance} end
        Port
    end
end
