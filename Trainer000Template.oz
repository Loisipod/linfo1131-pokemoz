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
    action
    Trainers
    Timer
    GCPort

    % Feel free to modify it as much as you want to build your own agents :) !

    % Helper => returns an integer between [0, N]
    fun {GetRandInt N} {OS.rand} mod N end

    % Helper => returns the id of first trainer or (if no trainer is in range) pokemoz in range
    fun {TrainerAround Surround}
        for elem in Surround do
            if elem == trainer() then elem.id end
        end
        ~1
    end

    fun {PokemozAround Surround}
        for elem in Surround do
            if elem == pokemoz() then elem.id end
        end
        return ~1
    end

    fun {ClosestTarget type}
        local targetlist chosentarget dist in
            chosentarget = ~1
            if type == pokemoz then targetlist = pokemozlist
            else targetlist = trainerslist 
            end
            for target in targetlist do
                if chosentarget == ~1 then
                    chosentarget = target.id
                    dist = {Abs (State.id.x-target.x)} + {Abs (State.id.y-target.y)}
                elseif {Abs (State.id.x-target.x)} + {Abs (State.id.y-target.y)} < dist then
                    chosentarget = target.id
                    dist = {Abs (State.id.x-target.x)} + {Abs (State.id.y-target.y)}
                end
            chosentarget
            end
        end
    end
    
    fun {FindPath TargetX TargetY}
        fun {FindPathRec CurrentX CurrentY Visited}
            local Moves NextVisited in
                Moves = [record(dx:1 dy:0 dir:"south") 
                         record(dx:~1 dy:0 dir:"north") 
                         record(dx:0 dy:1 dir:"east") 
                         record(dx:0 dy:~1 dir:"west")]
                NextVisited = {Dictionary.put Visited record(X:CurrentX Y:CurrentY) nil}
                if CurrentX == TargetX andthen CurrentY == TargetY then
                    skip % Base case: target reached
                else
                    for M in Moves do
                        local NextX NextY in
                            NextX = CurrentX + M.dx
                            NextY = CurrentY + M.dy
                            if Map[NextX NextY] == 0 andthen {Dictionary.has NextVisited record(X:NextX Y:NextY)} == false then
                                if NextX == TargetX andthen NextY == TargetY then
                                    % Return the direction for the first valid move
                                    M.dir
                                else
                                    {FindPathRec NextX NextY NextVisited}
                                end
                            end
                        end
                    end
                end
            end
        end
    in
        {FindPathRec State.id.x State.id.y {Dictionary.new}}
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
            case State.state
            of neutral() then {Agent {Adjoin State state(turnnr:Msg.TurnNr surround:Msg.Surround pokemozlist:Msg.PokemOzList state:{Adjoin State.state neutral(Hp:Msg.trainer.hp SHp:Msg.trainer.hp action:0)})}}
            [] scared() then {Agent {Adjoin State state(turnnr:Msg.TurnNr surround:Msg.Surround pokemozlist:Msg.PokemOzList state:{Adjoin State.state scared(Hp:Msg.trainer.hp action:0)})}}
            [] attacked() then {Agent {Adjoin State state(turnnr:Msg.TurnNr surround:Msg.Surround pokemozlist:Msg.PokemOzList state:{Adjoin State.state attacked(Hp:Msg.trainer.hp action:0)})}}
            [] aggressive() then {Agent {Adjoin State state(turnnr:Msg.TurnNr surround:Msg.Surround pokemozlist:Msg.PokemOzList state:{Adjoin State.state aggressive(Hp:Msg.trainer.hp action:0)})}}
            end
            {TrainerDo}
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
            of attacked() then {Agent {Adjoin State state(map:Msg.Map trainerslist:Msg.Trainers state:{Adjoin State.state attacked(action:1)})}}
            [] scared() then {Agent {Adjoin State state(map:Msg.Map trainerslist:Msg.Trainers state:{Adjoin State.state scared(action:1)})}}
            [] aggressive() then {Agent {Adjoin State state(map:Msg.Map trainerslist:Msg.Trainers state:{Adjoin State.state aggressive(action:1)})}}
            end
            {TrainerBecome}
        end

        fun {TrainerBecome}
            case State.state of neutral() then 
                if State.state.Hp < 4 then {Agent {AdjoinAt State state {Adjoin State.state scared(Hp:State.state.Hp timer:0 action:State.state.action)}}}
                elseif State.state.SHp > State.state.Hp then {Agent {AdjoinAt State state {Adjoin State.state attacked(Hp:State.state.Hp action:State.state.action)}}}
                else {Agent State}
                end
            [] scared() then 
                if State.state.Hp > 3 then {Agent {AdjoinAt State state {Adjoin State.state neutral(Hp:State.state.Hp SHp:State.state.Hp action:State.state.action)}}}
                elseif State.state.timer == 0 then {Agent {AdjoinAt State state {AdjoinAt State.state timer {Adjoin State.state.timer 3}}}}
                else {Agent {AdjoinAt State state {AdjoinAt State.state timer {Adjoin State.state.timer State.state.timer~1}}}}
                end
            [] attacked() then
                if State.state.hit == 1 then {Agent {AdjoinAt State state {Adjoin State.state neutral(Hp:State.state.Hp SHp:State.state.Hp action:State.state.action)}}}
                else {Agent {AdjoinAt State state {Adjoin State.state aggressive(Hp:State.state.Hp timer:10-{GetRandInt 5} action:State.state.action)}}}
                end
            [] aggressive() then 
                if State.state.Hp > 13 then {Agent State}
                elseif State.state.timer =< 0 then {Agent {AdjoinAt State state {Adjoin State.state neutral(Hp:State.state.Hp SHp:State.state.Hp action:State.state.action)}}}
                else {Agent {AdjoinAt State state {AdjoinAt State.state timer {Adjoin State.state.timer State.state.timer~1}}}}
                end
            end
        end

        fun {TrainerDo}
            if State.state.action == 1 then raise error('Multiple actions in a single turn is not allowed') end
            elseif State.turnnr == 100 then {Send State.GCPort lookMap(State.id.id State.turnnr)}
            else 
                if {TrainerAround State.surround} \= ~1 then
                    {Send State.GCPort attack(State.id.id State.turnnr {TrainerAround State.surround})}
                else
                    case State.state
                    of neutral() then
                        if {PokemozAround State.surround} \= ~1 then 
                            {Send State.GCPort attack(State.id.id State.turnnr {PokemozAround State.surround})}
                        else
                            local TargetId TargetX TargetY in
                                TargetId = {ClosestTarget pokemoz}
                                for pokemoz in State.PokemOzList do
                                    if pokemoz.id == TargetId then
                                        TargetX = pokemoz.x
                                        TargetY = pokemoz.Y
                                    end
                                end
                                {Send State.GCPort moveTo(State.id.id {FindPath TargetX TargetY})}
                            end
                        end
                    [] scared() then
                        if State.state.timer == 0 then 
                            {Send State.GCPort lookMap(State.id.id State.turnnr)}
                        elseif {PokemozAround State.surround} \= ~1 then
                            {Send State.GCPort attack(State.id.id State.turnnr {PokemozAround State.surround})}
                        else
                            local TargetId TargetX TargetY in
                                TargetId = {ClosestTarget pokemoz}
                                for pokemoz in State.PokemOzList do
                                    if pokemoz.id == TargetId then
                                        TargetX = pokemoz.x
                                        TargetY = pokemoz.y
                                    end
                                end
                                {Send State.GCPort moveTo(State.id.id {FindPath TargetX TargetY})}
                            end
                        end
                    [] attacked() then
                        {Send State.GCPort lookMap(State.id.id State.turnnr)}
                    [] aggressive() then
                        local TargetId TargetX TargetY in
                            TargetId = {ClosestTarget trainer}
                            for trainer in State.TrainersList do
                                if trainer.id == TargetId then
                                    TargetX = trainer.x
                                    TargetY = trainer.y
                                end
                            end
                            if coord(TargetX TargetY) \= coord(State.id.x State.id.y) then 
                                {Send State.GCPort moveTo(State.id.id {FindPath TargetX TargetY})}
                            else
                                {Send State.GCPort lookMap(State.id.id State.turnnr)}
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
    % proc {Handler Msg | Upcoming Instance}
    %     case Msg of Dummy then {Handler Upcoming Instance}
    %     [] Attack then {Attack Msg}
    %     [] MoveSelf then {MoveSelf Msg}
    %     [] LookMap then {LookMap Msg}
    %         else {Handler Upcoming Instance}
    %     end
    % end

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
