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
goog.require "goog.asserts"

colors =
     red: [255,0,0]
     green: [0,255,0]
     blue: [0,0,255]
     empty: [255,255,255]

blankColor = "empty"
colorKeys = (key for key, value of colors)
randomColor = () ->
          colorKeys[Math.floor(Math.random()*4)]

animationLength = 0.3
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



#States
state_ready="READY"
state_falling="FALLING"
state_swapping="SWAPPING"
class Cell
     constructor: (@world, @color, @x,@y) ->
          @limeobj = new lime.Sprite().setAnchorPoint(0,0)
          @limeobj.setPosition(@world.translatex(@x), @world.translatey(@y))
          @limeobj.setSize @world.blocksizex, @world.blocksizey

          @setColor(@color)
          @world.appendChild @limeobj

          @state = state_ready




     setColor: (@color) ->
          [redC,greenC,blueC] = colors[@color]
          if @color == blankColor
               @limeobj.setFill redC,greenC,blueC,1
               @limeobj.setFill redC,greenC,blueC,0
          else
               @limeobj.setFill redC,greenC,blueC,1


     matches: (other) ->
          not other.isEmpty() and not @isEmpty() and (other.color == @color)

     isEmpty: ->
          @color == blankColor

     resetPosition: ->
          @limeobj.setPosition(@world.translatex(@x), @world.translatey(@y))

     animateMove: (time, easing) ->
          newco = new goog.math.Coordinate(@world.translatex(@x), @world.translatey(@y))
          if not goog.math.Coordinate.equals(newco, @limeobj.getPosition())
               0
          @state = state_swapping
          animation = new lime.animation.MoveTo(@world.translatex(@x), @world.translatey(@y))
          animation.setDuration(time)
          animation.setEasing(easing)
          goog.events.listen animation, lime.animation.Event.STOP, =>
               @state = state_ready
               @resetPosition()
               @world.update()
          @limeobj.runAction(animation)

     animateFall: ->
          @animateMove(0.3, lime.animation.Easing.LINEAR)
     animateSwap: ->
          @animateMove(0.3, lime.animation.Easing.EASE)
     isReady: ->
          @state == state_ready

     swapWith: (other) ->
          if other.isReady() and @isReady()
               [@limeobj, other.limeobj] = [other.limeobj, @limeobj]
               temp = @color
               @setColor other.color
               other.setColor temp

               @animateSwap()
               other.animateSwap()

     fallFrom: (other) ->
          if other.isReady() and @isReady()
               [@limeobj, other.limeobj] = [other.limeobj, @limeobj]

               @color = other.color
               other.setColor(blankColor)
               other.resetPosition()

               @animateFall()







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
          @world.update = => @checkForMatch()
          @world.getBelow = (x,y) =>
               if y < @world.height
                    @grid[y+1][x]
               else
                    null
          @grid = (@emptyRow(y) for y in [0..@world.height])
          for y in [@world.height..0]
               for x in [0..@world.width]
                    if (y == @world.height) or (not @grid[y+1][x].isEmpty())
                         @grid[y][x].setColor(randomColor())

          @selection = new Selection(@world)
          @selection.set(0,@world.height)
          console.log "Constructed"

     randomRow: (y) ->
          (new Cell(@world, randomColor(), x, y) for x in [0..@world.width])

     emptyRow: (y) ->
          (new Cell(@world, blankColor, x, y) for x in [0..@world.width])

     swap: (x1=@selection.x,y1=@selection.y,x2=@selection.x+1,y2=@selection.y) ->
          if x1 == y1 and x2 == y2
               return
          @grid[y1][x1].swapWith(@grid[y2][x2])

          #@grid[y1][x1].move(x2, y2)
          #@grid[y2][x2].move(x1, y1)
          #[@grid[y1][x1], @grid[y2][x2]] = [@grid[y2][x2], @grid[y1][x1]]

     fall: (x) ->
          moving = false
          for y in [@world.height-1..0]
               if (@grid[y+1][x].isEmpty()) and not @grid[y][x].isEmpty() and @grid[y+1][x].isReady() and @grid[y][x].isReady()
                    moving=true
               if moving
                    @grid[y+1][x].fallFrom(@grid[y][x])
          moving

     play_move: (x,y) ->
          @selection.set(@selection.x + x, @selection.y + y)
     play_swap: ->
          @swap()
          @checkForMatch()
          lime.scheduleManager.callAfter((=> @checkForMatch()), this, animationLength*1005)

     matches: (x1,y1,x2,y2,x3,y3) ->
          @grid[y1][x1].isReady() and @grid[y2][x2].isReady() and @grid[y3][x3].isReady() and @grid[y1][x1].matches(@grid[y2][x2]) and @grid[y1][x1].matches(@grid[y3][x3])


     checkForMatch: ->
          matchGrid = ((false for x in [0..@world.width]) for y in [0..@world.height])
          for x in [0..@world.width]
               for y in [0..@world.height]
                    @grid[y][x].resetPosition()
                    if x - 2 >= 0 and @matches(x,y,x-1,y,x-2,y)
                         matchGrid[y][x-ax] = true for ax in [0..2]
                    if y - 2 >= 0 and @matches(x,y,x,y-1,x,y-2)
                         matchGrid[y-ay][x] = true for ay in [0..2]

          changed = false
          for x in [0..@world.width]
               for y in [0..@world.height]
                    if matchGrid[y][x]
                         changed = true
                         @grid[y][x].setColor(blankColor)
          for x in [0..@world.width]
               changed = @fall(x)
          if changed
               @checkForMatch()

runTest = ->
     scene = new lime.Scene()
     world = new World(scene, 2, 3)
     world.update = -> 0
     world.getBelow = -> null
     cell1 = new Cell(world, "red", 0,0)
     cell2 = new Cell(world, "blue", 1,0)
     cell4 = new Cell(world, blankColor, 0,1)
     cell3 = new Cell(world, "green", 0,2)
     goog.asserts.assert (cell1.color == "red")
     goog.asserts.assert (cell2.color == "blue")
     goog.asserts.assert (cell3.color == "green")
     goog.asserts.assert (cell4.color == blankColor)
     cell1.swapWith(cell2)
     goog.asserts.assert (cell1.color == "blue")
     goog.asserts.assert (cell2.color == "red")
     cell4.fallFrom(cell3)
     goog.asserts.assert (cell1.color == "blue")
     goog.asserts.assert (cell4.color == "green")
     goog.asserts.assert (cell3.color == blankColor)





crack.start = ->
     runTest()
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
               when goog.events.KeyCodes.Q
                    for y in [world.height..0]
                         for x in [world.width..0]
                              board.grid[y][x].animateMove()
     ))
     
     director.replaceScene scene

goog.exportSymbol "crack.start", crack.start
