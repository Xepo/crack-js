goog.provide "crack"
goog.require "goog.events.KeyCodes"
goog.require "lime.Director"
goog.require "lime.Polygon"
goog.require "lime.Scene"
goog.require "lime.Layer"
goog.require "lime.Circle"
goog.require "lime.Label"
goog.require "lime.animation.Spawn"
goog.require "lime.animation.FadeTo"
goog.require "lime.animation.ScaleTo"
goog.require "lime.animation.MoveTo"

colors =
     red: [255,0,0]
     green: [0,255,0]
     blue: [0,0,255]
     empty: [255,255,255]

blankColor = "empty"
colorKeys = (key for key, value of colors)
randomColor = () ->
          colorKeys[Math.floor(Math.random()*4)]

class World
     constructor: (@scene, @width=6, @height=10) ->
          @pxwidth = 512
          @pxheight = 512
          @target = new lime.Layer().setPosition(0, 0).setSize(@pxwidth, @pxheight)
          @blocksizex = @pxwidth / @width
          @blocksizey = @pxheight / @height
          @scene.appendChild @target

     translatex: (x) ->
          x * @blocksizex
     translatey: (y) ->
          y * @blocksizey

     appendChild: (child) ->
          @target.appendChild child



class Block
     constructor: (@world, @color, @x,@y) ->
          @limeobj = new lime.Sprite().setAnchorPoint(0,0)
          @limeobj.setPosition(@world.translatex(@x), @world.translatey(@y))
          @limeobj.setSize @world.blocksizex, @world.blocksizey

          [redC,greenC,blueC] = colors[@color]
          @limeobj.setFill redC,greenC,blueC
          @world.appendChild @limeobj

     move: (@x,@y) ->
          @limeobj.setPosition(@world.translatex(@x), @world.translatey(@y))

     matches: (other) ->
          other.color != blankColor and @color != blankColor and (other.color == @color)

     isEmpty: ->
          @color == blankColor




class Selection
     constructor: (@world, @x=0,@y=0) ->
          @limeobj = new lime.Polygon()
          l = 0
          m = @world.blocksizex
          r = @world.blocksizex*2
          t = 0
          b = @world.blocksizey

          @limeobj.addPoints(l,t, r,t, r,b, l,b, l,t, m,t, m,b, l,b)
          @limeobj.setStroke(2, 'rgb(0,0,0)')
          @world.appendChild @limeobj

     set: (x,y) ->
          if x >= 0 and x < @world.width and y >= 0 and y <= @world.height
               @x = x
               @y = y
               @limeobj.setPosition @world.translatex(x),@world.translatey(y)




class Board
     constructor: (@world) ->
          @grid = (@randomRow(y) for y in [0..@world.height])
          @selection = new Selection(@world)
          @selection.set(0,@world.height)
          console.log "Constructed"

     randomRow: (y) ->
          (new Block(@world, randomColor(), x, y) for x in [0..@world.width])

     emptyRow: (y) ->
          (new Block(@world, emptyColor, x, y) for x in [0..@world.width])

     swap: (x1=@selection.x,y1=@selection.y,x2=@selection.x+1,y2=@selection.y) ->
          @grid[y1][x1].move(x2, y2)
          @grid[y2][x2].move(x1, y1)
          [@grid[y1][x1], @grid[y2][x2]] = [@grid[y2][x2], @grid[y1][x1]]

     fall: (x,y) ->
          if y < @world.height
               if @grid[y+1][x].isEmpty()
                    @swap(x,y, x,y+1)
                    @fall x, y+1


     play_move: (x,y) ->
          @selection.set(@selection.x + x, @selection.y + y)
     play_swap: ->
          @swap()
          @fall(@selection.x, @selection.y)
          @fall(@selection.x+1, @selection.y)

     checkForMatch: (x,y) ->
          false







crack.start = ->
     color_for_selected = new lime.fill.Color(0x808080)
     stroke_for_selected = new lime.fill.Stroke(2, color_for_selected)
     normal_stroke = new lime.fill.Stroke(0, new lime.fill.Color(0xFFFFFF))
     director = new lime.Director(document.body, 1024, 768)
     director.setDisplayFPS(false)
     scene = new lime.Scene()
     world = new World(scene)
     board = new Board(world)

     goog.events.listen(document, ['keydown'], ((e) ->
          switch e.keyCode
               when (goog.events.KeyCodes.LEFT), goog.events.KeyCodes.A
                    board.play_move(-1,0)
               when goog.events.KeyCodes.RIGHT, goog.events.KeyCodes.D
                    board.play_move(1,0)
               when goog.events.KeyCodes.DOWN, goog.events.KeyCodes.S
                    board.play_move(0,1)
               when goog.events.KeyCodes.UP, goog.events.KeyCodes.W
                    board.play_move(0,-1)
               when goog.events.KeyCodes.SPACE, goog.events.KeyCodes.K
                    board.play_swap()
     ))
     
     director.replaceScene scene

goog.exportSymbol "crack.start", crack.start
