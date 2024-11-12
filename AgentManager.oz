functor

import
    System
    Trainer000Template
export
    'spawnBot': SpawnBot
define

    % Spawn the agent and returns its port
    fun {SpawnBot BotName Init}
        % Init => init(Id GameControllerPort Map)
        case BotName of
            'Trainer000Template' then {Trainer000Template.getPort Init}
        else 
            {Trainer000Template.getPort Init}
        end
    end
end