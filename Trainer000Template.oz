functor

import
    OS
    System
export
    'getPort': SpawnAgent
define
% retourn nil si il y a un mur ou un pokemoz dans la direction, l'id du trainer sinon
fun {FirstInLine State Dir}
    % si la position est occupée par un mur ou un bot et si bot renvoie un record trainer ou pokemoz
    fun {IsOccupied Position BotList}
        if {Nth State.map Position}==1 then 'wall'
        else
            case BotList of H|T then 
                if H.x+H.y*28 == Position then H
                else {IsOccupied Position T} end
            else nil end
        end
    end
    % check toutes les cases dans la dir de l'attaquant
    fun {Check State Position Dir} AllBots in 
        AllBots = State.nearest|State.pokzmozs
        case Dir of 'north' then
            if Position-28 > 0 then
                if {IsOccupied Position-28 AllBots}==nil then
                    {Check State Position-28 Dir}
                else
                    case {Record.label {IsOccupied Position-28 AllBots}} of'trainer' then
                        {IsOccupied Position-28 AllBots}.id
                    [] 'pokemoz' then nil
                    else nil end
                end
            else nil end
        [] 'south' then
            if Position+28 < 812 then
                if {IsOccupied Position+28 AllBots}==nil then
                    {Check State Position+28 Dir}
                else
                    case {Record.label {IsOccupied Position+28 AllBots}} of'trainer' then
                        {IsOccupied Position+28 AllBots}.id
                    [] 'pokemoz' then nil
                    else nil end
                end
            else nil end
        [] 'east' then
            if Position+1 < (State.y+1)*28 then
                if {IsOccupied Position+1 AllBots}==nil then
                    {Check State Position+1 Dir}
                else
                    case {Record.label {IsOccupied Position+1 AllBots}} of 'trainer' then
                        {IsOccupied Position+1 AllBots}.id
                    [] 'pokemoz' then nil
                    else nil end
                end
            else nil end
        [] 'west' then
            if Position-1 > (State.y)*28 then
                if {IsOccupied Position-1 AllBots}==nil then
                    {Check State Position-1 Dir}
                else
                    case {Record.label {IsOccupied Position-1 AllBots}} of 'trainer' then
                        {IsOccupied Position-1 AllBots}.id
                    [] 'pokemoz' then nil
                    else nil end
                end
            else nil end
        else 
            nil 
        end
    end
in
    {Check State State.x+State.y*28 Dir}
end
    fun {BeamSuccess State TrainerList}
        case TrainerList of H|T then 
            if State.x == H.x then 
                if State.y < H.y andthen {FirstInLine State 'south'}\= nil then {Send State.gcport beamAttack(State.id State.turn 'south')} true
                else 
                    if {FirstInLine State 'north'}\= nil then {Send State.gcport beamAttack(State.id State.turn 'north')} true else {BeamSuccess State T} end
                end
            elseif State.y == H.y then 
                if State.x < H.x andthen {FirstInLine State 'east'}\= nil then {Send State.gcport beamAttack(State.id State.turn 'east')} true
                else 
                    if {FirstInLine State 'west'}\= nil then {Send State.gcport beamAttack(State.id State.turn 'west')} true else {BeamSuccess State T} end
                end
            else {BeamSuccess State T} end
        else false end
    end

    % Helper => returns an integer between [0, N]
    fun {GetRandInt N} {OS.rand} mod N end

    fun {GetNearest State BotList Nearest}
        case BotList of H|T then
            if {Abs State.x-H.x}+{Abs State.y-H.y}+1 < {Abs State.x-Nearest.x}+{Abs State.y-Nearest.y} then
                {GetNearest State T H}
            else {GetNearest State T Nearest} end
        else Nearest end
    end
    fun {Len L}
        fun {Length L Count}
            case L of H|T then {Length T Count+1} 
            else Count end
        end
    in
        {Length L 0}
    end
    fun {AppendList L1 L2}
        case L1 of H|T then 
            H|{AppendList T L2}
        else L2 end
    end
    fun {IsAround SurroundingsList Type}
        fun {TypeList SurroundingsList Type}
            case SurroundingsList of H|T then
                if {Record.is H} andthen {Label H}==Type then H|{TypeList T Type}
                else {TypeList T Type}end
            else nil end
        end
        fun {LowestHp TrainerList Lowest}
            case TrainerList of H|T then
                if H.hp < Lowest.hp then {LowestHp T H}
                else {LowestHp T Lowest} end
            else Lowest end
        end
        TypedList
    in
        TypedList = {TypeList SurroundingsList Type}
        if TypedList == nil then false()
        elseif {Len TypedList} == 1 then true(Type:TypedList.1)
        else true(Type:{LowestHp TypedList TypedList.1}) end
    end
    fun {Nth L N}
        if N<0 then 1 
        else
            case L of nil then 1
            [] H|T then 
                if N==0 then H
                else {Nth T N-1} end 
            end
        end
    end
    fun {IsIn L Elem}
        case L of H|T then 
            if H==Elem then true
            else {IsIn T Elem}end
        else false end
    end
    fun {IsFree State Position}
        if {Nth State.map Position}==1 then false
        else true end
    end

    
    fun {MoveTowardsNearest State Nearest}
        if State.nextMove == none() then
            if State.x < Nearest.x then 
                if State.surroundings.east=='empty' then {Send State.gcport moveTo(State.id 'east')}{Agent {Adjoin State state(lastAttack:none())}}
                elseif State.y =< 14 andthen State.surroundings.south=='empty' then {Send State.gcport moveTo(State.id 'south')}{Agent {Adjoin State state(lastAttack:none())}}
                elseif State.y >= 14 andthen State.surroundings.south=='empty' then {Send State.gcport moveTo(State.id 'north')}{Agent {Adjoin State state(lastAttack:none())}}
                else {Send State.gcport moveTo(State.id 'west')}{Agent {Adjoin State state(lastAttack:none())}} end

            elseif State.x > Nearest.x then 
                if State.surroundings.west=='empty' then {Send State.gcport moveTo(State.id 'west')}{Agent {Adjoin State state(lastAttack:none())}}
                elseif State.y =< 14 andthen State.surroundings.south=='empty' then {Send State.gcport moveTo(State.id 'south')}{Agent {Adjoin State state(lastAttack:none())}}
                elseif State.y >= 14 andthen State.surroundings.south=='empty' then {Send State.gcport moveTo(State.id 'north')}{Agent {Adjoin State state(lastAttack:none())}}
                else {Send State.gcport moveTo(State.id 'east')}{Agent {Adjoin State state(lastAttack:none())}} end

            elseif State.y > Nearest.y then 
                if State.surroundings.north=='empty' then {Send State.gcport moveTo(State.id 'north')}{Agent {Adjoin State state(lastAttack:none())}}
                elseif State.x =< Nearest.x andthen State.surroundings.east=='empty' then {Send State.gcport moveTo(State.id 'east')}{Agent {Adjoin State state(lastAttack:none() nextMove:moveTo(State.id 'north'))}}
                elseif State.x >= Nearest.x andthen State.surroundings.west=='empty' then {Send State.gcport moveTo(State.id 'west')}{Agent {Adjoin State state(lastAttack:none() nextMove:moveTo(State.id 'north'))}}
                else {Send State.gcport moveTo(State.id 'south')}{Agent {Adjoin State state(lastAttack:none())}} end

            else
                if State.surroundings.south=='empty' then {Send State.gcport moveTo(State.id 'south')}{Agent {Adjoin State state(lastAttack:none())}}
                elseif State.x =< Nearest.x andthen State.surroundings.east=='empty' then {Send State.gcport moveTo(State.id 'east')}{Agent {Adjoin State state(lastAttack:none() nextMove:moveTo(State.id 'south'))}}
                elseif State.x >= Nearest.x andthen State.surroundings.west=='empty' then {Send State.gcport moveTo(State.id 'west')}{Agent {Adjoin State state(lastAttack:none() nextMove:moveTo(State.id 'south'))}}
                else {Send State.gcport moveTo(State.id 'north')}{Agent {Adjoin State state(lastAttack:none())}} end
            end

        else {Send State.gcport State.nextMove}{Agent {Adjoin State state(nextMove:none() lastAttack:none())}} end
    end

    % TODO: Complete this concurrent functional agent
    fun {Agent State}
        fun {AttackSuccessful attackSuccessful(Victim)}
            if State.kill=='maybe' then {Agent {Adjoin State state(lastAttack:success() kill:'yes')}}
            else {Agent {Adjoin State state(lastAttack:success())}} end
        end
        fun {AttackFailed attackFailed()}
            {Agent {Adjoin State state(lastAttack:failed() kill:'no' hasToBeamAttack:false)}}
        end
        fun {MapInfo mapInfo(Map TrainerList)}
            %if State.id==1 then{System.show TrainerList}else skip end
            {Agent {Adjoin State state(map:Map hasToBeamAttack:true latestOpponentstInfo:TrainerList nearest:{GetNearest State {AppendList TrainerList State.pokemozs} TrainerList.1})}}
        end
        fun {NewTurn newTurn(TurnNr trainer(id:Id hp:Hp name:Name x:X y:Y) surroundings(east:East ne:NE north:North nw:NW se:SE south:South sw:SW west:West) PokemozList)}
            %if State.id==1 andthen State.pokemozs\=nil then{System.show State.nearest}{System.show {GetNearest State State.pokemozs State.pokemozs.1}}else skip end
            {Send State.agentPort play()}
            if State.pokemozs==nil then 
                {Agent {Adjoin State state(turn:TurnNr hp:Hp x:X y:Y surroundings:surroundings(east:East ne:NE north:North nw:NW se:SE south:South sw:SW west:West) pokemozs:PokemozList)}}
            else {Agent {Adjoin State state(turn:TurnNr hp:Hp x:X y:Y surroundings:surroundings(east:East ne:NE north:North nw:NW se:SE south:South sw:SW west:West) nearest:{GetNearest State State.pokemozs State.nearest} pokemozs:PokemozList)}} end
        end

        fun {Play play()}
            if State.map == nil then {Send State.gcport lookMap(State.id State.turn)}{Agent State}
            elseif State.lastAttack\=failed() andthen {Label {IsAround {Record.toList State.surroundings} 'trainer'}} == true then
                if {IsAround {Record.toList State.surroundings} 'trainer'}.trainer.hp==1 then
                    {Send State.gcport attack(State.id State.turn {IsAround {Record.toList State.surroundings} 'trainer'}.trainer.id)}{Agent {Adjoin State state(kill:'maybe')}}
                else {Send State.gcport attack(State.id State.turn {IsAround {Record.toList State.surroundings} 'trainer'}.trainer.id)}{Agent State} end
            elseif State.hasToBeamAttack then 
                if {BeamSuccess State latestOpponentstInfo} then {Agent State} 
                else {Agent {Adjoin State state(hasToBeamAttack:false)}} end
            elseif State.lastAttack\=failed() andthen {Label {IsAround {Record.toList State.surroundings} 'pokemoz'}} == true then 
                if {IsAround {Record.toList State.surroundings} 'pokemoz'}.pokemoz.hp==1 then 
                    {Send State.gcport attack(State.id State.turn {IsAround {Record.toList State.surroundings} 'pokemoz'}.pokemoz.id)}{Agent {Adjoin State state(kill:'maybe')}}
                else {Send State.gcport attack(State.id State.turn {IsAround {Record.toList State.surroundings} 'pokemoz'}.pokemoz.id)}{Agent State} end                
            elseif State.pokemozs == nil andthen State.hasToLook then {Send State.gcport lookMap(State.id State.turn)}{Agent {Adjoin State state(hasToLook:false nearest:bot(x:999 y:999))}}
            elseif State.kill == 'yes' then {Send State.gcport lookMap(State.id State.turn)}{Agent {Adjoin State state(kill:'no')}}

            else {MoveTowardsNearest State State.nearest} end
        end

    in

        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'newTurn':NewTurn
                'attackSuccessful':AttackSuccessful
                'attackFailed':AttackFailed
                'mapInfo':MapInfo
                'play':Play
            )
        in
            %if State.id ==1 then {System.show Msg} else skip end
            if {HasFeature Interface Dispatch} then% andthen State.id == 1 then
                {Interface.Dispatch Msg}
            else
                %{System.show log('Unhandle message' Dispatch)}
                {Agent State}
            end
        end
    end

    proc {Handler Msg | Upcoming Instance}
        if Msg \= shutdown() then {Handler Upcoming {Instance Msg}} end
    end

    fun {SpawnAgent init(Id GCPort Map)}
        Stream
        Port = {NewPort Stream}

        Instance = {Agent state(
            'agentPort':Port
            'id': Id
            'gcport': GCPort
            'turn':0-1
            'map':nil
            'latestOpponentstInfo':nil
            'pokemozs':nil
            'nearest':bot()
            'hp':10
            'x':0-1
            'y':0-1
            'surroundings':nil
            'lastAttack':none()
            'nextMove':none()
            'kill':false
            'hasToLook':false
            'hasToBeamAttack':false
            
        )}
    in 
        thread {Handler Stream Instance} end
        Port
    end
end
