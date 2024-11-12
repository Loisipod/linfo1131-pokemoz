functor

import
    OS
    System
    Application
    QTk at 'x-oz://system/wp/QTk.ozf'
export
    'spawn': SpawnGraphics
define
    IMAGE_SIZE = 32
    CD = {OS.getCWD}
    FONT = {QTk.newFont font('size': 12)}
    WALL_TILE = {QTk.newImage photo(file: CD # '/ress/wall.gif')}
    GROUND_TILE = {QTk.newImage photo(file: CD # '/ress/ground.gif')}
    
    class GameObject
        attr 'id' 'type' 'sprite' 'x' 'y'

        meth init(Id Type Sprite X Y)
            'id' := Id
            'type' := Type
            'sprite' := Sprite
            'x' := X
            'y' := Y
        end

        meth getType($) @type end

        meth render(Buffer)
            {Buffer copy(@sprite 'to': o(@x @y))}
        end

        meth update(GCPort) skip end
    end

    class Entity from GameObject
        attr 'hp' 'hphandle' 'name'

        meth init(Id Type Sprite X Y Hp HPHandle Name)
            GameObject, init(Id Type Sprite X Y)
            'hp' := Hp
            'hphandle' := HPHandle
            'name' := Name
        end

        meth setHp(Hp)
            'hp' := Hp
        end

        meth update(GCPort)
            {@hphandle set('text': @id # " " # @name # " Hp: " # @hp)}
        end
    end

    class Bot from Entity
        attr 'isMoving' 'moveDir' 'targetX' 'targetY'

        meth init(Id Type Sprite X Y Hp HPHandle Name)
            Entity, init(Id Type Sprite X Y Hp HPHandle Name)
            'isMoving' := false
            'targetX' := X
            'targetY' := Y
        end

        meth setTarget(Dir)
            'isMoving' := true
            'moveDir' := Dir
            if Dir == 'north' then
                'targetY' := @y - IMAGE_SIZE
            elseif Dir == 'south' then
                'targetY' := @y + IMAGE_SIZE
            elseif Dir == 'east' then
                'targetX' := @x + IMAGE_SIZE
            elseif Dir == 'west' then
                'targetX' := @x - IMAGE_SIZE
            end
        end

        meth move(GCPort)
            if @moveDir == 'north' then
                'y' := @y - 4
            elseif @moveDir == 'south' then
                'y' := @y + 4
            elseif @moveDir == 'east' then
                'x' := @x + 4
            elseif @moveDir == 'west' then
                'x' := @x - 4
            end

            if @x == @targetX andthen @y == @targetY then
                NewX = @x div IMAGE_SIZE
                NewY = @y div IMAGE_SIZE
            in
                'isMoving' := false
                {Send GCPort movedTo(@id @type NewX NewY)}
            end

            /* if @targetX - @x div IMAGE_SIZE > 0 then
                'x' := @x + 4
            elseif @targetX - @x div IMAGE_SIZE < 0 then
                'x' := @x - 4
            end

            if @targetY - @y div IMAGE_SIZE > 0 then
                'y' := @y + 4
            elseif @targetY - @y div IMAGE_SIZE < 0 then
                'y' := @y - 4
            end

            if @isMoving andthen @x div 4 == @targetX andthen @y div 4 == @targetY then
                'isMoving' := false
                {Send GCPort movedTo(@id @type @targetX @targetY)}
            end */
        end

        meth update(GCPort)
            if @isMoving then
                {self move(GCPort)}
            end
            Entity, update(GCPort)
        end
    end

    class Pokemoz from Entity
        attr 'lvl' 'Name'
        meth init(Id Name Img X Y Hp HPHandle)
            Sprite
        in
            Sprite = {QTk.newImage photo(file: CD # '/ress/pokemoz/' # Img height: 32 width: 32)}
            lvl := Hp
            Entity, init(Id 'pokemoz' Sprite X Y Hp HPHandle Name)
        end
    end

    class Trainer from Bot
        attr 'hp'
        meth init(Id Name Img X Y Hp HPHandle)
            Sprite = {QTk.newImage photo(file: CD # '/ress/' # Img)}
        in
            Bot, init(Id 'trainer' Sprite X Y Hp HPHandle Name)
            'hp' := Hp
        end
    end

    class Graphics
        attr
            'buffer' 'buffered' 'canvas' 'window'
            'ids' 'gameObjects'
            'background'
            'running'
            'gcPort'
            'nbots'
        meth init(GCPort)
            Height = 928
            Width = 896 + 6*32
        in
            'running' := true
            'gcPort' := GCPort

            'nbots' := 0

            'buffer' := {QTk.newImage photo('width': Width 'height': Height)}
            'buffered' := {QTk.newImage photo('width': Width 'height': Height)}

            'window' := {QTk.build td(
                canvas(
                    'handle': @canvas
                    'width': Width
                    'height': Height
                    'background': 'black'
                )
                button(
                    'text': "close"
                    'action' : proc {$} {Application.exit 0} end
                )
            )}

            {@canvas create('image' Width div 2 Height div 2 'image': @buffer)}
            'background' := {QTk.newImage photo('width': Width 'height': Height)}
            {@window 'show'}

            'gameObjects' := {Dictionary.new}
            'ids' := 0
        end

        meth isRunning($) @running end

        meth genId($)
            'ids' := @ids + 1
            @ids
        end

        meth buildMap(Map)
            Z = {NewCell 0}
        in
            for K in Map do
                X = @Z mod 28
                Y = @Z div 28
            in
                if K == 0 then
                    {@background copy(GROUND_TILE 'to': o(X * IMAGE_SIZE Y * IMAGE_SIZE))}
                elseif K == 1 then
                    {@background copy(WALL_TILE 'to': o(X * IMAGE_SIZE Y * IMAGE_SIZE))}
                elseif K == 2 then
                    {@background copy(GROUND_TILE 'to': o(X * IMAGE_SIZE Y * IMAGE_SIZE))}
                end
                Z := @Z + 1
            end
        end

        meth spawnBot(Type Name Image X Y Hp $)
            Bot
            Id = {self genId($)}
            HPHandle
        in

            {@canvas create('text' 992 @nbots * 32 + 16 'text': '' 'fill': 'white' 'font': FONT 'handle': HPHandle)}
            if Type == 'trainer' then
                Bot = {New Trainer init(Id Name Image X * IMAGE_SIZE Y * IMAGE_SIZE Hp HPHandle)}
            else
                Bot = {New Pokemoz init(Id Name Image X * IMAGE_SIZE Y * IMAGE_SIZE Hp HPHandle)}
            end

            'nbots' := @nbots + 1

            {Dictionary.put @gameObjects Id Bot}
            {Send @gcPort movedTo(Id Type X Y)}
            Id
        end

        meth dispawnBot(Id)
            {Dictionary.remove @gameObjects Id}
            'nbots' := @nbots - 1
        end

        meth moveBot(Id Dir)
            Bot = {Dictionary.condGet @gameObjects Id 'null'}
        in
            if Bot \= 'null' then
                {Bot setTarget(Dir)}
            end
        end

        meth updateHp(Id Hp)
            Bot = {Dictionary.condGet @gameObjects Id 'null'}
        in
            if Bot \= 'null' then
                {Bot setHp(Hp)}
            end
        end

        meth update()
            GameObjects = {Dictionary.items @gameObjects}
        in
            {@buffered copy(@background 'to': o(0 0))}
            for Gobj in GameObjects do
                {Gobj update(@gcPort)}
                {Gobj render(@buffered)}
            end
            {@buffer copy(@buffered 'to': o(0 0))}
        end
    end

    fun {NewActiveObject Class Init}
        Stream
        Port = {NewPort Stream}
        Instance = {New Class Init}
    in
        thread
            for Msg in Stream do {Instance Msg} end
        end

        proc {$ Msg} {Send Port Msg} end
    end

    fun {SpawnGraphics Port FpsMax}
        Active = {NewActiveObject Graphics init(Port)}
        FrameTime = 1000 div FpsMax
        % TODO CHANGER CE GESTIONNAIRE DE FPS
        proc {Ticker}
            StartTime EndTime
        in
            if {Active isRunning($)} then
                StartTime = {Time.time}
                {Active update()}
                %{System.show {Record.get {Time.get} milliSeconds}}
                EndTime = FrameTime - ({Time.time} - StartTime)
                %{System.show EndTime}
                if EndTime > 0 then
                    {Delay EndTime}
                end
                %{Delay FrameTime}
                {Ticker}
            end
        end
        BotId
    in
        thread {Ticker} end
        Active
    end
end
