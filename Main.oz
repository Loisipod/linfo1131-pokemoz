functor
%todo : function (beam, attack, move, checkmap) + Gamecontroller + ia de base pour trainer
import
    Input
    System
    Graphics
    AgentManager
    Application
define
     % Check the Adjoin and AdjoinAt function, documentation: (http://mozart2.org/mozart-v1/doc-1.4.0/base/record.html#section.records.records)

    proc {Broadcast Tracker Msg}
        {Record.forAll Tracker proc {$ Tracked} if Tracked.alive  andthen Tracked.port \= nil then {Send Tracked.port Msg} end end}
    end
    % TODO: define here any auxiliary functions or procedures you may need
    fun {NewPortObject2 Proc}
        P
    in
        thread Sin in
            {NewPort Sin P}
            for Msg in Sin do {Proc Msg} end
        end
        P
    end

    fun {Timer}
        {NewPortObject2
        proc {$ Msg}
            case Msg of starttimer(T Pid) then
                thread {Delay T} {Send Pid stoptimer} end
            end
        end}
    end
    % get the nth element of a list
    fun {Nth L N}
        if N<0 then nil 
        else
            case L of nil then nil
            [] H|T then 
                if N==0 then H
                else {Nth T N-1} end 
            end
        end
    end 

    fun {GetPosition State Id}
        State.trainers.Id.x+(State.trainers.Id.y)*28
    end
    
    proc {SendAgents Msg AgentsList}
        case AgentsList of H|T then {Send H.port Msg} {SendAgents Msg T}
        else skip end
    end

    fun {CanMove State Id Dir}
        Position
        %ajouter le cas où il y a un pokemoz
        fun {IsOccupied Position TrainersList}
            case TrainersList of H|T then 
                if H.x+H.y*28 == Position then true
                else {IsOccupied Position T} end
            else false end
        end
    in
        case Dir of 'north' then
            Position={GetPosition State Id}-28
        []'south' then 
            Position={GetPosition State Id}+28
        []'east' then 
            Position={GetPosition State Id}+1
        []'west' then 
            Position={GetPosition State Id}-1
        else skip end
        if {Nth State.map Position}==1 then false
        else 
            if {IsOccupied Position {Record.toList State.trainers}} then false
            else true end
        end
    end

    fun {IsAround State Victim Center}
        if {GetPosition State Victim} == Center+1 then true
        elseif {GetPosition State Victim} == Center-1 then true
        elseif {GetPosition State Victim} == Center+28 then true
        elseif {GetPosition State Victim} == Center-28 then true
        elseif {GetPosition State Victim} == Center+29 then true
        elseif {GetPosition State Victim} == Center+27 then true
        elseif {GetPosition State Victim} == Center-27 then true
        elseif {GetPosition State Victim} == Center-29 then true
        else false end
    end
    % retourn nil si il y a un mur ou un pokemoz dans la direction, l'id du trainer sinon
    fun {FirstInLine State Dir Id}
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
        fun {Check State Position Dir}
            case Dir of 'north' then
                if Position-28 > 0 then
                    if {IsOccupied Position-28 {Record.toList State.trainers}}==nil then
                        {Check State Position-28 Dir}
                    else
                        if {Record.label {IsOccupied Position-28 {Record.toList State.trainers}}}=='trainer' then
                            {IsOccupied Position-28 {Record.toList State.trainers}}.id
                        else nil end
                    end
                else nil end
            [] 'south' then
                if Position+28 > 0 then
                    if {IsOccupied Position+28 {Record.toList State.trainers}}==nil then
                        {Check State Position+28 Dir}
                    else
                        if {Record.label {IsOccupied Position+28 {Record.toList State.trainers}}}=='trainer' then
                            {IsOccupied Position+28 {Record.toList State.trainers}}.id
                        else nil end
                    end
                else nil end
            [] 'east' then
                if Position+1 > 0 then
                    if {IsOccupied Position+1 {Record.toList State.trainers}}==nil then
                        {Check State Position+1 Dir}
                    else
                        if {Record.label {IsOccupied Position+1 {Record.toList State.trainers}}}=='trainer' then
                            {IsOccupied Position+1 {Record.toList State.trainers}}.id
                        else nil end
                    end
                else nil end
            [] 'west' then
                if Position-1 > 0 then
                    if {IsOccupied Position-1 {Record.toList State.trainers}}==nil then
                        {Check State Position-1 Dir}
                    else
                        if {Record.label {IsOccupied Position-1 {Record.toList State.trainers}}}=='trainer' then
                            {IsOccupied Position-1 {Record.toList State.trainers}}.id
                        else nil end
                    end
                else nil end
            else 
                {System.show 'pas une direction'} 
                nil 
            end
        end
    in
        {Check State {GetPosition State Id} Dir}
    end
    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
    % and ensure a turn-by-turn game
    fun {GameController State}
        % Example of function to handle the MoveTo messages sent by the trainers (this is not compliant with the PokemOz rules)
        fun {MoveTo moveTo(Id Dir)}
            % doit verif si un autre bot va pas sur la même case
            if {CanMove State Id Dir} then {State.gui moveBot(Id Dir)}
            else {Send State.trainers.Id.port 'CannotMove'} end    
            {GameController State}
        end

    % Function to handle the movedTo message sent back by the GUI
        fun {MovedTo movedTo(Id Type X Y)}
            % TODO: Create a NewState record with Adjoin/AdjoinAt function and return it
            case Type of 'trainer' then 
                    {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Id {Adjoin State.trainers.Id trainer(x:X y:Y)}}}}
                []'pokemoz' then {GameController State}
            else {GameController State} end
        end

        % attaque classique, ne doit pas faire de degat si attaqué
        fun {Attack attack(Id TurnNr Victim)}
            if {HasFeature State.trainers Victim} then
                if {IsAround State Victim {GetPosition State Id}} then 
                    {Send State.trainers.Id.port 'attackSuccessful(Victim)'}
                    %faire un case pour les pokemoz
                    if State.trainers.Victim.hp-1==0 then
                        {State.gui updateHp(Victim State.trainers.Victim.hp-1)}
                        {State.gui dispawnBot(Victim)}
                        {GameController {AdjoinAt State trainers {Record.subtract State.trainers Victim}}}
                    else
                        {State.gui updateHp(Victim State.trainers.Victim.hp-1)}
                        {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Victim {Adjoin State.trainers.Victim trainer(hp:State.trainers.Victim.hp-1)}}}}
                    end
                else 
                    {Send State.trainers.Id.port 'attackFailed'}
                    {GameController State}
                end
            else 
                {Send State.trainers.Id.port 'attackFailed'}
                {GameController State}
            end
        end

         % BEAAAAAAAAAAAM
        fun {BeamAttack beamAttack(Id TurnNr Dir)}Victim in
            Victim={FirstInLine State Dir Id}
            %{State.gui updateHp(Id Hp)}
            if Victim==nil then
                {Send State.trainers.Id.port 'attackFailed'}
                {GameController State}
            else 
                {Send State.trainers.Id.port 'beaaam'}
                %faire un case pour les pokemoz
                if State.trainers.Victim.hp-1==0 then
                    {State.gui updateHp(Victim State.trainers.Victim.hp-1)}
                    {State.gui dispawnBot(Victim)}
                    {GameController {AdjoinAt State trainers {Record.subtract State.trainers Victim}}}
                else
                    {State.gui updateHp(Victim State.trainers.Victim.hp-1)}
                    {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Victim {Adjoin State.trainers.Victim trainer(hp:State.trainers.Victim.hp-1)}}}}
                end
            end
        end

         % lookmap
        fun {LookMap lookMap(Id TurnNr)}
            {Send State.trainers.Id.port mapInfo(State.map {Record.toList State.trainers})}
            {GameController State} 
        end
    in
        % TODO: complete the interface and discard and report unknown messages
        % every function is a field in the interface() record

        %ordre : attack, move, lookmap
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'moveTo': MoveTo
                'movedTo': MovedTo
                'beamAttack': BeamAttack
                'attack': Attack
                'lookMap': LookMap
                %TODO: add other messages here
                %...
            )
        in

            if {HasFeature Interface Dispatch} then
                {Interface.Dispatch Msg}
            else
                % {System.show log('Unhandle message' Dispatch)}
                {GameController State}
            end
        end
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        {Handler Upcoming {Instance Msg}}
    end

    % TODO: Spawn the agents
    proc {StartGame}
        X
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 30}

        Map = {Input.genMap}
        {GUI buildMap(Map)}

        Instance Trainers PokemOzs

        fun {CreateTrainers L Trainers Port Map GUI}
            Trainer Id TrainerPort
        in
            case L of H|T then
                Id = {GUI spawnBot('trainer' H.name H.image H.x H.y H.hp $)}
                TrainerPort = {AgentManager.spawnBot H.agent init(Id Port Map)}
                Trainer = trainer(id:Id alive:true port:TrainerPort x:H.x y:H.y move:true name:H.name hp:H.hp)
                {CreateTrainers T {Adjoin Trainers trainers(Id: Trainer)} Port Map GUI}
            else Trainers
            end
        end

    in
        % TODO: log the winning team name and the score then use {Application.exit 0}
            
        % Example trainer move (do not use in final version)
        thread 
            {Delay 1000}
            {GUI spawnBot('pokemoz' 'Arcarnoz' 'arcanoz.gif' 7 7 10 X)}
            {Delay 1000}
            {Send Port moveTo(1 'east')}
            {Delay 1000}
            {Send Port moveTo(1 'south')}
            {Delay 1000}
            {Send Port moveTo(1 'west')}
            {Delay 1000}
            {Send Port attack(1 5 2)}
            {Delay 1000}
            {Send Port moveTo(1 'north')}
            {Delay 1000}
            {Send Port beamAttack(1 10 'east')}
            {Delay 1000}
            {Send Port moveTo(1 'north')}
            {Delay 1000}
            {Send Port moveTo(1 'east')}
            {Delay 1000}
            {Send Port attack(1 5 2)}
        end
        %thread {Delay 1000}{GUI spawnBot('pokemOz' 'arcanoz' 'pokemoz/arcanoz.gif' 10 5 3 $)}end 

        % thread
        %     {Send Port lookMap(2 10)}
        %     {Delay 1000}
        %     {Send Port moveTo(2 'west')}
        %     {Delay 1000}
        %     {Send Port moveTo(2 'south')}
        %     {Delay 1000}
        %     {Send Port moveTo(2 'east')}
        %     {Delay 1000}
        %     {Send Port moveTo(2 'north')}
        % end
        

        % thread {Delay 1000} {GUI updateHp(1 5)} end

        Instance = {GameController state(
            'gui': GUI
            'map': Map
            'trainers': {CreateTrainers Input.trainers trainers() Port Map GUI}
            'port': Port
            'pokemozs':PokemOzs
        )}

        {Handler Stream Instance}
    end

    {StartGame}
end
