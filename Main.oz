functor
    % TODO coordiner les actions, conditions de victoire, générer des pokemozs aléatoirement
import
    Input
    System
    Graphics
    AgentManager
    Application
    OS
define
     % Check the Adjoin and AdjoinAt function, documentation: (http://mozart2.org/mozart-v1/doc-1.4.0/base/record.html#section.records.records)
    proc {Broadcast Tracker Msg}
        {Record.forAll Tracker proc {$ Tracked} if Tracked.alive  andthen Tracked.port \= nil then {Send Tracked.port Msg} end end}
    end
    % TODO: define here any auxiliary functions or procedures you may need
    fun {Len L}
        fun {Length L Count}
            case L of H|T then {Length T Count+1} 
            else Count end
        end
    in
        {Length L 0}
    end
    fun {Delete L X}
        case L of H|T then
           if H==X then
              T
           else
              H|{Delete T X}
           end
        else nil end
     end
     fun {ReplaceNth L Elem Nth}
        case L of H|T then 
            if Nth==0 then
                Elem|{ReplaceNth T Elem Nth-1}
            else H|{ReplaceNth T Elem Nth-1} end
        else nil end
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

    fun {GetRandomFile}
        Files = {OS.getDir 'ress/pokemoz'} % Obtenir la liste des fichiers
        RandomIndex = {GetRandInt {Len Files}} % Générer un index aléatoire
    in
        {Nth Files RandomIndex} % Retourner un fichier aléatoire
    end

    fun {GetRandInt N} {OS.rand} mod N end
    fun {RandomEmptyPlace Map} X in
        X={GetRandInt 750}+29
        if {Nth Map X}==0 then 
            X
        else
            {RandomEmptyPlace Map}
        end
    end
    proc {AddPokemozRandom Port Map}
        Position={RandomEmptyPlace Map} 
        X = Position mod 28
        Y = Position div 28
        File = {GetRandomFile}
        PokemozName = {String.toAtom {String.tokens File &.}.1}
    in
        if {GetRandInt 5}==1 then
            {Send Port addpokemoz(PokemozName File  X Y {GetRandInt 4}+1)}
        else skip end
    end

    proc {Sender Port StreamActionRecord TurnNr Map TrainersAlive}
        fun {Getter Port StreamActionRecord IdList}
            case IdList of H|T then 
                if {Value.isFuture StreamActionRecord.H}==false then 
                    {Send Port StreamActionRecord.H.1}
                    {Getter Port {Adjoin StreamActionRecord streamActionRecord(H:StreamActionRecord.H.2)} T}
                else {Getter Port StreamActionRecord T} end
            else StreamActionRecord end
        end
        fun {AllReady StreamActionRecord IdList}
            case IdList of H|T then 
                if {Value.isFuture StreamActionRecord.H} then 
                    false
                else {AllReady StreamActionRecord T} end
            else true end
        end
    in
        if TurnNr+2 > 0 then
            {AddPokemozRandom Port Map}
            {Send Port newturn(turn:TurnNr)}
            {Delay 600}
            if {AllReady StreamActionRecord {Cell.access TrainersAlive}}==false then
                {Delay 1000}
            else skip end
            {Sender Port {Getter Port StreamActionRecord {Cell.access TrainersAlive}} TurnNr-1 Map TrainersAlive}
        else {Send Port endgame()} end
    end

    fun {CreatePlayerPort Port}
        P Stream
    in
        thread
            {NewPort Stream P}
            for Msg in Stream do skip end
        end
        obj(p:P s:Stream)
    end
    %renvoie le trainer avec le plus d'hp
    fun {GetHighestHp Trainers HighestHp}
        case Trainers of H|T then
            if H.hp > HighestHp.hp then
                {GetHighestHp T H}
            elseif H.hp < HighestHp.hp then
                {GetHighestHp T HighestHp}
            else 
                {GetHighestHp T multiple(hp:HighestHp.hp)}
            end
        else HighestHp end
    end

    fun {AppendList L1 L2}
        case L1 of H|T then 
            H|{AppendList T L2}
        else L2 end
    end
    % Donne la position sur la map, la premiere position est 0,0
    fun {GetPosition State Id}
        State.Id.x+(State.Id.y)*28
    end

    fun {CanMove State Id Dir}
        Position
        fun {IsOccupied Position BotList}
            case BotList of H|T then 
                if H.x+H.y*28 == Position then true
                else {IsOccupied Position T} end
            else false end
        end
    in
        if {HasFeature State.trainers Id}==false then false
        else 
            case Dir of 'north' then
                Position={GetPosition State.trainers Id}-28
            []'south' then 
                Position={GetPosition State.trainers Id}+28
            []'east' then 
                Position={GetPosition State.trainers Id}+1
            []'west' then 
                Position={GetPosition State.trainers Id}-1
            else skip end
            if {Nth State.map Position}==1 then false
            else 
                if {IsOccupied Position {AppendList {Record.toList State.trainers} {Record.toList State.pokemozs}}} then false
                else true end
            end
        end
    end

    fun {IsAround State Victim Center}
        if {GetPosition {Adjoin State.trainers State.pokemozs} Victim} == Center+1 then true
        elseif {GetPosition {Adjoin State.trainers State.pokemozs} Victim} == Center-1 then true
        elseif {GetPosition {Adjoin State.trainers State.pokemozs} Victim} == Center+28 then true
        elseif {GetPosition {Adjoin State.trainers State.pokemozs} Victim} == Center-28 then true
        elseif {GetPosition {Adjoin State.trainers State.pokemozs} Victim} == Center+29 then true
        elseif {GetPosition {Adjoin State.trainers State.pokemozs} Victim} == Center+27 then true
        elseif {GetPosition {Adjoin State.trainers State.pokemozs} Victim} == Center-27 then true
        elseif {GetPosition {Adjoin State.trainers State.pokemozs} Victim} == Center-29 then true
        else false end
    end
    fun {AllSurround State TrainerList}
        fun {Surround State Id} S1 S2 S3 S4 S5 S6 S7
            Surround = surroundings()
            Position = {GetPosition State.trainers Id}
            AllBots = {AppendList {Record.toList State.trainers} {Record.toList State.pokemozs}}
            fun {IsOccupied Position BotList}
                if {Nth State.map Position}==1 then 'wall'
                else
                    case BotList of H|T then 
                        if H.x+H.y*28 == Position then
                            case {Label H} of 'trainer' then
                                trainer(id:H.id name:H.name x:H.x y:H.y hp:H.hp)
                            else pokemoz(id:H.id name:H.name x:H.x y:H.y level:H.level hp:H.hp)end
                        else {IsOccupied Position T} end
                    else 'empty' end
                end
            end
        in
            S1 = {Adjoin Surround surroundings(north:{IsOccupied Position-28 AllBots})}
            S2 = {Adjoin S1 surroundings(ne:{IsOccupied Position-27 AllBots})}
            S3 = {Adjoin S2 surroundings(east:{IsOccupied Position+1 AllBots})}
            S4 = {Adjoin S3 surroundings(se:{IsOccupied Position+29 AllBots})}
            S5 = {Adjoin S4 surroundings(south:{IsOccupied Position+28 AllBots})}
            S6 = {Adjoin S5 surroundings(sw:{IsOccupied Position+27 AllBots})}
            S7 = {Adjoin S6 surroundings(west:{IsOccupied Position-1 AllBots})}
            {Adjoin S7 surroundings(nw:{IsOccupied Position-29 AllBots})}
        end
        fun {MakeRecord State TrainerList AllSurround}
            case TrainerList of H|T then Id=H.id in
                {MakeRecord State T {Adjoin AllSurround surroundings(Id:{Surround State Id})}}
            else AllSurround end
        end
    in
        {MakeRecord State TrainerList surroundings()}
    end

    proc {SendAgentsTurnInfo AgentsList TurnNr AllSurround PokemozList}
        case AgentsList of H|T then 
            Id = H.id 
        in 
            {Send H.port newTurn(TurnNr trainer(id:Id x:H.x y:H.y name:H.name hp:H.hp) AllSurround.Id PokemozList)}
            {SendAgentsTurnInfo T TurnNr AllSurround PokemozList}
        else skip end
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
        fun {Check State Position Dir Id} AllBots in 
            AllBots = {AppendList {Record.toList State.trainers} {Record.toList State.pokemozs}}
            case Dir of 'north' then
                if Position-28 > 0 then
                    if {IsOccupied Position-28 AllBots}==nil then
                        {Check State Position-28 Dir Id}
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
                        {Check State Position+28 Dir Id}
                    else
                        case {Record.label {IsOccupied Position+28 AllBots}} of'trainer' then
                            {IsOccupied Position+28 AllBots}.id
                        [] 'pokemoz' then nil
                        else nil end
                    end
                else nil end
            [] 'east' then
                if Position+1 < (State.trainers.Id.y+1)*28 then
                    if {IsOccupied Position+1 AllBots}==nil then
                        {Check State Position+1 Dir Id}
                    else
                        case {Record.label {IsOccupied Position+1 AllBots}} of 'trainer' then
                            {IsOccupied Position+1 AllBots}.id
                        [] 'pokemoz' then nil
                        else nil end
                    end
                else nil end
            [] 'west' then
                if Position-1 > (State.trainers.Id.y)*28 then
                    if {IsOccupied Position-1 AllBots}==nil then
                        {Check State Position-1 Dir Id}
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
        {Check State {GetPosition State.trainers Id} Dir Id}
    end


    % Functions pour la prévisu des actions
    fun {TestAttacks State ListOfRecords}
        % regarde si Attacker se fait attacker
        fun {IsUnderAttack State L BotId}
            case L of H|T then
                case H of attack(Id TurnNr Victim) then
                    if {HasFeature {Adjoin State.trainers State.pokemozs} Victim} then
                        if BotId==Victim andthen {IsAround State Victim {GetPosition State.trainers Id}} then true
                        else {IsUnderAttack State T BotId} end
                    else {IsUnderAttack State T BotId} end
                [] beamAttack(Id TurnNr Dir) then
                    if BotId=={FirstInLine State Dir Id} then true
                    else {IsUnderAttack State T BotId}end
                else false end % cannot occur
            else false end
        end
        fun {IsAttackedOnce State ListOfRecords Attacked Count}
            case ListOfRecords of H|T then
                case H of attack(Id TurnNr Victim) then
                    if {HasFeature {Adjoin State.trainers State.pokemozs} Victim} then
                        if {IsAround State Victim {GetPosition State.trainers Id}} andthen Victim==Attacked then
                            if Count==1 then false
                            else {IsAttackedOnce State T Attacked 1} end
                        else {IsAttackedOnce State T Attacked Count} end
                    else {IsAttackedOnce State T Attacked Count} end
                [] beamAttack(Id TurnNr Dir) then
                    if Attacked=={FirstInLine State Dir Id} then
                        if Count==1 then false
                        else {IsAttackedOnce State T Attacked 1} end
                    else {IsAttackedOnce State T Attacked Count} end
                else true end % cannot occur
            else true end
        end
        fun {Builder State ListOfRecords L NewListOfRecords}
            case L of H|T then
                case H of attack(Id TurnNr Victim) then
                    if {IsUnderAttack State ListOfRecords Id}==false andthen {IsAttackedOnce State ListOfRecords Victim 0} then 
                        {Builder State ListOfRecords T H|NewListOfRecords}
                    else 
                        {Send State.trainers.Id.port attackFailed()}
                        {Builder State ListOfRecords T NewListOfRecords}
                    end
                [] beamAttack(Id TurnNr Dir) then
                    if {IsUnderAttack State ListOfRecords Id}==false andthen {IsAttackedOnce State ListOfRecords {FirstInLine State Dir Id} 0} then 
                        {Builder State ListOfRecords T H|NewListOfRecords}
                    else 
                        {Send State.trainers.Id.port attackFailed()}
                        {Builder State ListOfRecords T NewListOfRecords}
                    end
                else nil end
            else NewListOfRecords end
        end 
    in
        {Builder State ListOfRecords ListOfRecords nil}
    end
    fun {TestMoves State ListOfRecords}
        fun {NextPosition State moveTo(Id Dir)}
            case Dir of 'north' then {GetPosition State.trainers Id}-28
            [] 'south' then {GetPosition State.trainers Id}+28
            [] 'east' then {GetPosition State.trainers Id}+1
            [] 'west' then {GetPosition State.trainers Id}-1
            else 0-1 end
        end
        fun {IsUnique State L Elem Count}
            case L of H|T then
                if {NextPosition State Elem}==0-1 then
                    true
                else
                    if {NextPosition State Elem}=={NextPosition State H} then 
                        if Count==1 then false
                        else {IsUnique State T Elem 1}end
                    else {IsUnique State T Elem Count} end
                end
            else true end
        end
        fun {Builder State ListOfRecords L NewListOfRecords}
            case L of H|T then
                case H of moveTo(Id Dir)then 
                    if {IsUnique State ListOfRecords H 0} then {Builder State ListOfRecords T H|NewListOfRecords}
                    else {Builder State ListOfRecords T NewListOfRecords}end
                else nil end
            else NewListOfRecords end
        end
            
    in
        {Builder State ListOfRecords ListOfRecords nil}
    end

    % TODO: Complete this concurrent functional agent to handle all the message-passing between the GUI and the Agents
    % and ensure a turn-by-turn game
    fun {GameController State}
        fun {MoveTo moveTo(Id Dir)}
            if {HasFeature State.trainers Id} then
                if {CanMove State Id Dir} then X=State.trainers.Id.x Y=State.trainers.Id.y in
                    {State.gui moveBot(Id Dir)}
                    case Dir of 'north' then {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Id {Adjoin State.trainers.Id trainer(x:X y:Y-1)}}}}
                    [] 'south' then {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Id {Adjoin State.trainers.Id trainer(x:X y:Y+1)}}}}
                    [] 'east' then {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Id {Adjoin State.trainers.Id trainer(x:X+1 y:Y)}}}}
                    else {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Id {Adjoin State.trainers.Id trainer(x:X-1 y:Y)}}}} end
                else{GameController State}end    
                
            else
                {System.show 'Is probably dead'}
                {GameController State}
            end
        end

        fun {MovedTo movedTo(Id Type X Y)}
            {GameController State}
        end

        fun {Attack attack(Id TurnNr Victim)}
            if {HasFeature State.trainers Id} then
                if {HasFeature {Adjoin State.trainers State.pokemozs} Victim} then
                    if {IsAround State Victim {GetPosition State.trainers Id}} then
                        {Send State.trainers.Id.port attackSuccessful(Victim)}
                        case {Record.label {Adjoin State.trainers State.pokemozs}.Victim} of 'trainer' then
                            if State.trainers.Victim.hp-1==0 then Cell = State.trainersAlive Liste = @Cell NewState in
                                {State.gui updateHp(Victim State.trainers.Victim.hp-1)}
                                thread {Delay 100} {State.gui dispawnBot(Victim)}end
                                Cell:= {Delete Liste Victim} 
                                NewState = {Adjoin State state(map:{ReplaceNth State.map 0 {GetPosition State.trainers Victim}})}
                                {GameController {AdjoinAt NewState trainers {Record.subtract NewState.trainers Victim}}}
                            else
                                {State.gui updateHp(Victim State.trainers.Victim.hp-1)}
                                {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Victim {Adjoin State.trainers.Victim trainer(hp:State.trainers.Victim.hp-1)}}}}
                            end
                        else 
                            if State.pokemozs.Victim.hp-1==0 then NewState in
                                {State.gui updateHp(Victim State.pokemozs.Victim.hp-1)}
                                thread {Delay 100} {State.gui dispawnBot(Victim)}end
                                {State.gui updateHp(Id State.trainers.Id.hp + State.pokemozs.Victim.level)}
                                NewState = {AdjoinAt State trainers {AdjoinAt State.trainers Id {Adjoin State.trainers.Id trainer(hp:State.trainers.Id.hp + State.pokemozs.Victim.level)}}}
                                {GameController {AdjoinAt NewState pokemozs {Record.subtract NewState.pokemozs Victim}}}
                            else
                                {State.gui updateHp(Victim State.pokemozs.Victim.hp-1)}
                                {GameController {AdjoinAt State pokemozs {AdjoinAt State.pokemozs Victim {Adjoin State.pokemozs.Victim pokemoz(hp:State.pokemozs.Victim.hp-1)}}}}
                            end
                        end
                    else 
                        {Send State.trainers.Id.port attackFailed()}
                        {GameController State}
                    end
                else 
                    {Send State.trainers.Id.port attackFailed()}
                    {GameController State}
                end
            else
                {System.show 'is Probably dead'}
                {GameController State}
            end
        end

         % BEAAAAAAAAAAAM
        fun {BeamAttack beamAttack(Id TurnNr Dir)}Victim in
            if {HasFeature State.trainers Id} then 
                Victim={FirstInLine State Dir Id}
                if Victim==nil then
                    {Send State.trainers.Id.port attackSuccessful(Victim)}
                    {GameController State}
                else 
                    {Send State.trainers.Id.port 'beaaam'}
                    if State.trainers.Victim.hp-1==0 then Cell = State.trainersAlive Liste = @Cell NewState in
                        {State.gui updateHp(Victim State.trainers.Victim.hp-1)}
                        thread {Delay 100}{State.gui dispawnBot(Victim)}end
                        Cell:= {Delete Liste Victim}
                        NewState = {Adjoin State state(map:{ReplaceNth State.map 0 {GetPosition State.trainers Victim}})}
                        {GameController {AdjoinAt NewState trainers {Record.subtract NewState.trainers Victim}}}
                    else
                        {State.gui updateHp(Victim State.trainers.Victim.hp-1)}
                        {GameController {AdjoinAt State trainers {AdjoinAt State.trainers Victim {Adjoin State.trainers.Victim trainer(hp:State.trainers.Victim.hp-1)}}}}
                    end
                end
            else
                {System.show 'L attaquant n existe pas'}
                {GameController State}
            end
        end
        fun {HpPosOnly TrainersList NewList}
            case TrainersList of H|T then
                {HpPosOnly T trainer(hp:H.hp x:H.x y:H.y id:H.id name:H.name)|NewList}
            else NewList end
        end
        % envoie un record contenant la map d'origine et une liste de trainers sans le trainer qui demande les informations
        fun {LookMap lookMap(Id TurnNr)}
            if {HasFeature State.trainers Id} then NewState = {AdjoinAt State trainers {Record.subtract State.trainers Id}} in
                {Send State.trainers.Id.port mapInfo(State.map {HpPosOnly {Record.toList NewState.trainers} nil})}
            else 
                {System.show 'n existe pas'}
            end
            {GameController State} 
        end
        

        fun {AddPokemoz addpokemoz(Name Image X Y Hp)} 
            Id Pokemoz
            AllBots = {AppendList {Record.toList State.trainers} {Record.toList State.pokemozs}}
            fun {IsOccupied Position BotList}
                if {Nth State.map Position}==1 then 'wall'
                else
                    case BotList of H|T then 
                        if H.x+H.y*28 == Position then
                            case {Label H} of 'trainer' then
                                trainer(id:H.id name:H.name x:H.x y:H.y hp:H.hp)
                            else pokemoz(id:H.id name:H.name x:H.x y:H.y level:H.level hp:H.hp)end
                        else {IsOccupied Position T} end
                    else 'empty' end
                end
            end
        in
            if {Len {Record.toList State.pokemozs}} < 30 then 
                if {IsOccupied X+Y*28 AllBots}=='empty' then
                    Id={State.gui spawnBot('pokemoz' Name Image X Y Hp $)}
                    Pokemoz = pokemoz(id:Id name:Name x:X y:Y level:Hp hp:Hp)
                    {GameController {AdjoinAt State pokemozs {Adjoin State.pokemozs pokemozs(Id:Pokemoz)}}}
                else {GameController State} end
            else {GameController State} end
        end

        fun {SendNewTurnInfo sendNewTurnInfo(turn:TurnNr)}
            if TurnNr >= 0 then 
                {SendAgentsTurnInfo {Record.toList State.trainers} TurnNr {AllSurround State {Record.toList State.trainers}} {Record.toList State.pokemozs}}
            else skip end
            {GameController {Adjoin State state(turnNr:TurnNr)}}
        end
        
        
        fun {TestActions turnActions(attacks:Attacks moves:Moves lookmap:Lookmaps)} PostAttacks PostMoves in
            PostAttacks = {AttackMulti {TestAttacks State Attacks} {GameController State}}
            PostMoves = {MoveMulti {TestMoves State Moves} PostAttacks}
            {LookMapMulti Lookmaps PostMoves}
        end
        fun {AttackMulti Attacks Instance}
            case Attacks of H|T then
                {AttackMulti T {Instance H}}
            else Instance end
        end
        fun {MoveMulti Moves Instance}
            case Moves of H|T then
                {MoveMulti T {Instance H}}
            else Instance end
        end
        fun {LookMapMulti LookMaps Instance}
            case LookMaps of H|T then
                {LookMapMulti T {Instance H}}
            else Instance end
        end

    in
        fun {$ Msg}
            Dispatch = {Label Msg}
            Interface = interface(
                'moveTo': MoveTo
                'movedTo': MovedTo
                'beamAttack': BeamAttack
                'attack': Attack
                'lookMap': LookMap
                'addpokemoz':AddPokemoz
                'sendNewTurnInfo':SendNewTurnInfo
                'turnActions':TestActions
            )
        in
            if {Len {Record.toList State.trainers}}==1 then
                {System.show 'Ce joueur est le gagnant'}
                {System.show {Record.toList State.trainers}.1}
                {Application.exit 0}
            elseif State.turnNr==0-1 then 
                if {Label {GetHighestHp {Record.toList State.trainers}.2 {Record.toList State.trainers}.1}}=='multiple' then
                    {System.show 'Pas de gagnant'}
                    {Application.exit 0}
                else
                    {System.show 'Ce joueur est le gagnant'}
                    {System.show {GetHighestHp {Record.toList State.trainers}.2 {Record.toList State.trainers}.1}}
                    {Application.exit 0}
                end
            else skip end

            if {Label Msg}=='turnActions' then {System.show Msg}else skip end

            if {HasFeature Interface Dispatch} then
                {Interface.Dispatch Msg}
            else
                 {System.show Msg}
                {System.show log('Unhandle message' Dispatch)}
                {GameController State}
            end
        end
    end

    proc {Handler Stream R Instance}
            case Stream of Msg|Upcoming then
                case {Label Msg} of 'newturn' then NewInstance in
                    if Msg.turn \= Input.maxturns-1 then 
                        NewInstance = {Instance R}
                    else NewInstance = Instance end
                    {Handler Upcoming turnActions(attacks:nil moves:nil lookmap:nil) {NewInstance sendNewTurnInfo(turn:Msg.turn)}}
                [] 'moveTo' then {Handler Upcoming {Adjoin R turnActions(moves:Msg|R.moves)} Instance}
                [] 'attack' then {Handler Upcoming {Adjoin R turnActions(attacks:Msg|R.attacks)} Instance}
                [] 'beamAttack' then {Handler Upcoming {Adjoin R turnActions(attacks:Msg|R.attacks)} Instance}
                [] 'lookMap' then {Handler Upcoming {Adjoin R turnActions(lookmap:Msg|R.lookmap)} Instance}
                else {Handler Upcoming R {Instance Msg}} end
            else {System.show 'buggy'}skip end
    end

    proc {StartGame}
        Stream
        Port = {NewPort Stream}
        GUI = {Graphics.spawn Port 30}
        Map = {Input.genMap}
        {GUI buildMap(Map)}
        StreamActionRecord
        Instance
        Rec
        TrainersAlive



        fun {CreateTrainers L Trainers GUI Port StreamActionRecord}
            Trainer Id TrainerPort PlayerPort
        in
            case L of H|T then
                PlayerPort = {CreatePlayerPort Port}
                Id = {GUI spawnBot('trainer' H.name H.image H.x H.y H.hp $)}
                TrainerPort = {AgentManager.spawnBot H.agent init(Id PlayerPort.p Map)}
                Trainer = trainer(id:Id alive:true port:TrainerPort senderPort:PlayerPort x:H.x y:H.y move:true name:H.name hp:H.hp)
                {CreateTrainers T {Adjoin Trainers trainers(Id: Trainer)} GUI Port {Adjoin StreamActionRecord streamActionRecord(Id:PlayerPort.s)}}
            else rec(t:Trainers l:StreamActionRecord)
            end
        end

    in
        % thread
        %     {Delay 1000}
        %     {Send Port addpokemoz('Arcanoz' 'arcanoz.gif' 2 5 2)}
        %     {Send Port addpokemoz('blastoz' 'blastoz.gif' 4 4 2)} 
        % end

        Rec = {CreateTrainers Input.trainers trainers() GUI Port nil}
        StreamActionRecord = Rec.l
        TrainersAlive = {NewCell {Arity StreamActionRecord}}
        Instance = {GameController state(
            'gui': GUI
            'map': Map
            'trainers': Rec.t
            'port': Port
            'pokemozs':pokemozs()
            'turnNr':Input.maxturns
            'turnActions':turnActions(attacks:nil moves:nil lookmap:nil)
            'trainersAlive':TrainersAlive
        )}
        {Delay 1000}
        thread {Sender Port StreamActionRecord Input.maxturns-1 Map TrainersAlive} end
        {Handler Stream turnActions(attacks:nil moves:nil lookmap:nil) Instance}
    end
    {StartGame}
end
