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
    in
        % TODO: complete the interface and discard and report unknown messages
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                %TODO: add messages
                'dummy': Dummy
            )
        in
            {Interface.Dispatch Msg}
        end
    end

    % Please note: Msg | Upcoming is a pattern match of the Stream argument
    proc {Handler Msg | Upcoming Instance}
        if Msg \= shutdown() then {Handler Upcoming {Instance Msg}} end
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
