--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--
 
local widget = require "widget"
local tablespinner = require "tablespinner"

local SCREEN_WIDTH = display.contentWidth
local SCREEN_HEIGHT = display.contentHeight
local ROW_HEIGHT = 150
local REFRESH_ROW_HEIGHT = 50

local springStart = 0
local needToReload = false
local pullDown = nil
local reloadspinner
local  reloadInProgress = false

local tablespinnerImageSheet = graphics.newImageSheet( "tablespinner.png", tablespinner:getSheet() )	


--########################################
--  reloadTable() - 
--  a dummy timer-driven fn to simulate a reload
--########################################	
function reloadTable()
	
	
   function reloadcomplete()   -- this needs to be executed at the end of the reload fn
       
       if (reloadspinner ~= nil) and (reloadspinner.x ~= nil) then 
	       reloadspinner:stop()
    	   reloadspinner.alpha = 0
       end	 	   
	   transition.to( pullDown, { time=50, rotation=0, 
	   												onComplete= function() 
	   													if (pullDown ~= nil) and (pullDown.x ~= nil) then
	   														pullDown.alpha = 1; 
	   													end
	   													reloadInProgress = false; 
	   end } )        	 
	end


	-- Do your reload logic here. Then call the reloadComplete() directly instead of timer below
	reloadCompleteTimer = timer.performWithDelay( 2000, reloadcomplete, 1 )      	 
	
end



local function onRowRender( event )

	local row = event.row
	local index = row.index 

	if index== 1 then 
		if (pullDown == nil) or (pullDown.x == nil) then
			pullDown = display.newImage( row, "downloadarrow.png")
			pullDown.anchorX = 0.5
			pullDown.anchorY = 0.5
			pullDown.x = SCREEN_WIDTH * 0.5
			pullDown.y = REFRESH_ROW_HEIGHT * 0.5
		else
			pullDown.alpha = 1
		end

		if (reloadspinner == nil)  or (reloadspinner.x == nil) then
			reloadspinner = widget.newSpinner
			{
			    width = 128,
			    height = 128,
			    sheet = tablespinnerImageSheet,
			    startFrame = 1,
			    count = 8,
			    time = 800
			}
	
			reloadspinner.alpha = 0	
			reloadspinner.anchorX = 0.5
			reloadspinner.anchorY = 0.5
			reloadspinner.x = SCREEN_WIDTH*0.5
			reloadspinner.y = REFRESH_ROW_HEIGHT * 0.5
			
		end
		
		row:insert(reloadspinner)
		return
	end

	local rowText = display.newText(row, "ROW NUMBER "..(index-1), 0, 0,  "Times New Roman", 12)

	rowText.anchorX = 0.5
	rowText.anchorY = 0.5
	rowText.x = SCREEN_WIDTH *0.5
	rowText.y = ROW_HEIGHT * 0.5
	rowText:setFillColor( 0.1, 0.1, 0.1 )

end
	

local function onRowTouch( event )

end



local function scrollListener( event )
	
	if (reloadInProgress == true) then
		return true
	end
	
	if ( event.phase == "began" ) then

		needToReload = false
  
   elseif ( event.phase == "moved" ) and ( event.target.parent.parent:getContentPosition() > REFRESH_ROW_HEIGHT) then
        
		needToReload = true
        transition.to( pullDown, { time=200, rotation=180 } )

   elseif ( event.limitReached == true and event.phase == nil and  event.direction == "down" and needToReload == true ) then

		reloadInProgress = true  --turn this off at the end of the reload function
		needToReload = false
		pullDown.alpha = 0
		reloadspinner.alpha = 1
        reloadspinner:start()              
        reloadTable() 
 
   end    
   return true
end


local function insertTable()
	list:insertRow{  -- this is the row containing the pulldown arrow/spinner
				rowHeight =REFRESH_ROW_HEIGHT,
				rowColor = {  default = { 1, 1, 1 }, over = { 0.95, 0.95, 0.95, 1 }},
				}		
	-- now comes the real content			
	for i = 1, 10 do
		list:insertRow{
				rowHeight =ROW_HEIGHT,
				rowColor = {  default = { 1, 1, 1 }, over = { 0.95, 0.95, 0.95, 1 }},
				}		
	end
end

local function createWidgets()		
	toolbar = display.newImage( "toolbar.png")	
	toolbar.xScale = SCREEN_WIDTH / toolbar.contentWidth
	toolbar.anchorX = 0
	toolbar.anchorY = 0
	toolbar.x, toolbar.y = 0, 0

	list = widget.newTableView{
		top = toolbar.contentHeight - REFRESH_ROW_HEIGHT,
		height = SCREEN_HEIGHT - (toolbar.contentHeight - REFRESH_ROW_HEIGHT),
		maxVelocity = 1, 
		noLines = false,
		onRowRender = onRowRender,
		onRowTouch = onRowTouch,
		listener = scrollListener
	}
		
	toolbar:toFront()	
end




display.setStatusBar( display.HiddenStatusBar )	
createWidgets()
insertTable()

