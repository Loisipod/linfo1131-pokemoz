functor

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
        
        

    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
    % and ensure a turn-by-turn game
    fun {GameController State}
        % Example of function to handle the MoveTo messages sent by the trainers (this is not compliant with the PokemOz rules)
        fun {MoveTo moveTo(Id Dir)}
            {State.gui moveBot(Id Dir)}
            {GameController State}
        end

    % Function to handle the movedTo message sent back by the GUI
        fun {MovedTo movedTo(Id Type X Y)}
            % TODO: Create a NewState record with Adjoin/AdjoinAt function and return it
            {GameController State}
    end

    in
        % TODO: complete the interface and discard and report unknown messages
        % every function is a field in the interface() record
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'moveTo': MoveTo
                'movedTo': MovedTo
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
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 30}

        Map = {Input.genMap}
        {GUI buildMap(Map)}

        Instance Trainers

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
            {Send Port moveTo(1 'east')}
            {Delay 1000}
            {Send Port moveTo(1 'south')}
            {Delay 1000}
            {Send Port moveTo(1 'west')}
            {Delay 1000}
            {Send Port moveTo(1 'north')}
        end

        thread
            {Delay 1000}
            {Send Port moveTo(2 'west')}
            {Delay 1000}
            {Send Port moveTo(2 'south')}
            {Delay 1000}
            {Send Port moveTo(2 'east')}
            {Delay 1000}
            {Send Port moveTo(2 'north')}
        end

        thread {Delay 5000} {GUI updateHp(1 5)} end

        Instance = {GameController state(
            'gui': GUI
            'map': Map
            'trainers': {CreateTrainers Input.trainers trainers() Port Map GUI}
            'port': Port
        )}

        {Handler Stream Instance}
    end

    {StartGame}
end
