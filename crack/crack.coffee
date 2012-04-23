goog.provide "crack"
goog.require "goog.events.KeyCodes"
goog.require "lime.Director"
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

colorKeys = (key for key, value of colors)
randomColor = () ->
          colorKeys[Math.floor(Math.random()*3)]

class World
     constructor: (@scene, @width=6, @height=10) ->
          @pxwidth = 512
          @pxheight = 512
          @target = new lime.Layer().setPosition(0, 0).setSize(@pxwidth, @pxheight)
          @blocksizex = @pxwidth / @width
          @blocksizey = @pxheight / @height
          @scene.appendChild @target

          color_for_selected = new lime.fill.Color(100,100,100)
          @stroke_for_selected = new lime.fill.Stroke(200, color_for_selected)
          @normal_stroke = new lime.fill.Stroke(0, new lime.fill.Color(255,255,255))

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

     setSelected: (b) ->
          if b
               @limeobj.setStroke(3, 'rgb(50,50,50)')
          else
               @limeobj.setStroke null







class Board
     randomRow: (y) ->
          (new Block(@world, randomColor(), x, y) for x in [0..@world.width])

     setSelection: (x,y) ->
          if x >= 0 and x < @world.width and y >= 0 and y <= @world.height
               @grid[@selectedy][@selectedx].setSelected(false)
               @grid[@selectedy][@selectedx+1].setSelected(false)
               @selectedx = x
               @selectedy = y
               @grid[@selectedy][@selectedx].setSelected(true)
               @grid[@selectedy][@selectedx+1].setSelected(true)

     constructor: (@world) ->
          @grid = (@randomRow(y) for y in [0..@world.height])
          @selectedx = 0
          @selectedy = 0
          @setSelection(0,0)
          console.log "Constructed"

     move: (x,y) ->
          @setSelection(@selectedx + x, @selectedy + y)



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
          if (e.keyCode == goog.events.KeyCodes.LEFT)
               board.move(-1,0)
          if (e.keyCode == goog.events.KeyCodes.RIGHT)
               board.move(1,0)
          if (e.keyCode == goog.events.KeyCodes.DOWN)
               board.move(0,1)
          if (e.keyCode == goog.events.KeyCodes.UP)
               board.move(0,-1)
     ))
     
     director.replaceScene scene

goog.exportSymbol "crack.start", crack.start
