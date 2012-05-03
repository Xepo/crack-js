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
goog.require "lime.animation.ColorTo"
goog.require "lime.animation.ScaleTo"
goog.require "lime.animation.MoveTo"
goog.require "goog.asserts"

colors =
     empty: [255,255,255]
     red: [255,0,0]
     green: [0,255,0]
     blue: [0,0,255]
numberOfColors = Object.keys(colors).length

blankColor = "empty"
colorKeys = (key for key, value of colors)
randomColor = (allowBlank=false) ->
     if allowBlank
          colorKeys[Math.floor(Math.random()*numberOfColors)]
     else
          colorKeys[Math.floor(Math.random()*(numberOfColors-1)+1)]

animationLength = 0.15

class World
     constructor: (@scene, @width=6, @height=10) ->
          @pxwidth = 512
          @pxheight = 512
          @target = new lime.Layer().setPosition(0, 0).setSize(@pxwidth, @pxheight)
          @blocksizex = @pxwidth / @width
          @blocksizey = @pxheight / @height
          @raisey = 0
          @scene.appendChild @target

     translatex: (x) ->
          x * @blocksizex
     translatey: (y) ->
          (y * @blocksizey) + @raisey

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

     getObjColor: (isActive=(@y <= @world.height)) ->
          [redC,greenC,blueC] = colors[@color]
          if not isActive
               redC -= 90
               greenC -= 90
               blueC -= 90
          [redC, greenC, blueC]

     setColor: (@color) ->
          [redC, greenC, blueC] = @getObjColor()
          if @color == blankColor
               @limeobj.setFill redC,greenC,blueC,1
               @limeobj.setFill redC,greenC,blueC,0
          else
               @limeobj.setOpacity 1
               @limeobj.setFill redC,greenC,blueC,1


     matches: (other) ->
          not other.isEmpty() and not @isEmpty() and (other.color == @color)

     isEmpty: ->
          @color == blankColor

     resetPosition: ->
          if @animation?
               @animation.stop()
          @limeobj.setPosition(@world.translatex(@x), @world.translatey(@y))
          @state = state_ready

          #@setColor @color

     animateMove: (easing) ->
          newco = new goog.math.Coordinate(@world.translatex(@x), @world.translatey(@y))
          if not goog.math.Coordinate.equals(newco, @limeobj.getPosition())
               @stopSuperfluousAnimations()
               @state = state_swapping
               @animation = new lime.animation.MoveTo(@world.translatex(@x), @world.translatey(@y))
               @animation.setDuration(animationLength)
               @animation.setEasing(easing)
               @limeobj.runAction(@animation)

     animateFall: ->
          @animateMove(lime.animation.Easing.LINEAR)

     animateSwap: ->
          @animateMove(lime.animation.Easing.EASE)
          #@animation = new lime.animation.MoveTo(@world.translatex(@x), @world.translatey(@y))
          #@animation.setDuration(animationLength)
          #@limeobj.runAction(@animation)
          #console.log (@limeobj.getPosition() + " animating to " + @world.translatex(@x) + "," + @world.translatey(@y))

     stopSuperfluousAnimations: ->
          if @advanceanimation?
               @advanceanimation.stop()
               @setColor(@color)
     animateAdvance: ->
          if @isReady()
               [redC, greenC, blueC] = @getObjColor(false)
               @limeobj.setFill redC,greenC,blueC
               
               [redC,greenC,blueC] = @getObjColor(true)
               @advanceanimation = new lime.animation.ColorTo(redC,greenC,blueC)
               @advanceanimation.setDuration(animationLength)
               @limeobj.runAction(@advanceanimation)

     doMatch: ->
          @state = state_swapping
          @color = blankColor
          @animation = new lime.animation.FadeTo(0)
          @animation.setDuration(animationLength)
          @limeobj.runAction(@animation)

     isReady: ->
          @state == state_ready

     swapNow: (other) ->
          [@limeobj, other.limeobj] = [other.limeobj, @limeobj]
          temp = @color
          @setColor other.color
          other.setColor temp
          @stopSuperfluousAnimations()
          other.stopSuperfluousAnimations()

     swapWith: (other) ->
          if other.isReady() and @isReady()
               [@limeobj, other.limeobj] = [other.limeobj, @limeobj]
               temp = @color
               @setColor other.color
               other.setColor temp
               @stopSuperfluousAnimations()
               other.stopSuperfluousAnimations()

               other.animateSwap()
               @animateSwap()

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

     resetPosition: ->
          @limeobj.setPosition @world.translatex(@x),@world.translatey(@y)
     set: (x,y) ->
          if x >= 0 and x < @world.width and y >= 0 and y <= @world.height
               @x = x
               @y = y
               @resetPosition()




class Board
     constructor: (@world) ->
          @world.update = => @checkForMatch()
          @world.getBelow = (x,y) =>
               if y < @world.height
                    @grid[y+1][x]
               else
                    null
          @grid = (@emptyRow(y) for y in [0..@world.height+3])
          for y in [@world.height+3..0]
               for x in [0..@world.width]
                    if (y >= @world.height) or (not @grid[y+1][x].isEmpty())
                         @grid[y][x].setColor(randomColor(y < @world.height))

          @advanceAmt = 0.0
          @animating = 0

          @selection = new Selection(@world)
          @selection.set(0,@world.height)
          console.log "Constructed"

     advanceUntilStatic: ->
          if @checkForMatch()
               @reposition()
               @advanceUntilStatic()

     anyNonBlank: (row) ->
          for x in [0..@world.width]
               if not row[x].isEmpty()
                    return true
          return false
     newNextRow: ->
          if @anyNonBlank(@grid[@world.height+3])
               console.log("ERROR!")
          for x in [0..@world.width]
               @grid[@world.height+3][x].setColor(randomColor(false))

     endGame: ->
          console.log "Lost!"
          lime.scheduleManager.unschedule @advance, this

     reposition: ->
          if @animating
               return
          advanced = (@world.raisey < -@world.blocksizey)
          if advanced
               if @anyNonBlank(@grid[0])
                    @endGame()
                    return
               for y in [0..@world.height+2]
                    for x in [0..@world.width]
                         @grid[y][x].swapNow(@grid[y+1][x])
               @selection.y-=1
               @world.raisey += @world.blocksizey

          @selection.resetPosition()
          for y in [@world.height+3..0]
               for x in [0..@world.width]
                    @grid[y][x].resetPosition()
          if advanced
               for x in [0..@world.width]
                    @grid[@world.height][x].animateAdvance()
               @newNextRow()
               @checkForMatch()

     advance: (t) ->
          if not @animating
               @advanceAmt += t
               if @advanceAmt >= 100.0
                    @world.raisey -= @advanceAmt / 100.0
                    @advanceAmt = 0.0
                    @reposition()

     randomRow: (y) ->
          (new Cell(@world, randomColor(), x, y) for x in [0..@world.width])

     emptyRow: (y) ->
          (new Cell(@world, blankColor, x, y) for x in [0..@world.width])

     swap: (x1,y1,x2,y2) ->
          if x1 == x2 and y1 == y2
               return
          @grid[y1][x1].swapWith(@grid[y2][x2])

          #@grid[y1][x1].move(x2, y2)
          #@grid[y2][x2].move(x1, y1)
          #[@grid[y1][x1], @grid[y2][x2]] = [@grid[y2][x2], @grid[y1][x1]]

     fall: (x) ->
          ret = []
          for y in [@world.height-1..0]
               if (@grid[y+1][x].isEmpty()) and not @grid[y][x].isEmpty() and @grid[y+1][x].isReady() and @grid[y][x].isReady()
                    moving=true
               if moving
                    ret.push([y+1, x])
                    @grid[y+1][x].fallFrom(@grid[y][x])
          ret

     play_move: (x,y) ->
          @selection.set(@selection.x + x, @selection.y + y)
     play_swap: ->
          [x1,y1] = [@selection.x, @selection.y]
          [x2,y2] = [x1+1,y1]
          @swap(x1,y1,x2,y2)
          upd = =>
               @grid[y1][x1].resetPosition()
               @grid[y2][x2].resetPosition()
               @checkForMatch()

          lime.scheduleManager.callAfter(upd, this, animationLength*1005)

     matches: (x1,y1,x2,y2,x3,y3) ->
          @grid[y1][x1].isReady() and @grid[y2][x2].isReady() and @grid[y3][x3].isReady() and @grid[y1][x1].matches(@grid[y2][x2]) and @grid[y1][x1].matches(@grid[y3][x3])


     checkForMatch: ->
          matchGrid = ((false for x in [0..@world.width]) for y in [0..@world.height])
          affected = []
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
                         @grid[y][x].doMatch()
                         affected.push [y,x]
          for x in [0..@world.width]
               affected = affected.concat(@fall(x))


          if affected.length > 0
               @animating = true
               upd = (t) =>
                    @animating = false
                    for pos in affected
                         [y,x] = pos
                         @grid[y][x].resetPosition()
                         @grid[y][x].state = state_ready
                    @checkForMatch()

               lime.scheduleManager.callAfter(upd, this, animationLength*1000)
          changed

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

     lime.scheduleManager.schedule(board.advance, board)

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
