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

local SCREEN_WIDTH = display.contentWidth
local SCREEN_HEIGHT = display.contentHeight
local ROW_HEIGHT = 50

local itemList = {}


local function initData(count)
	
	for i = 1, count do
		itemList[i] = {}
		itemList[i].title = "Row "..i
	end
	
	for i = 1, count do
		list:insertRow{
				rowHeight =ROW_HEIGHT,
				rowColor = {  default = { 1, 1, 1 }, over = { 0.95, 0.95, 0.95, 1 }},
				}		
	end
		
end



local function onRowRender( event )

	local row = event.row
	local index = row.index 

	local rowText = display.newText(row, itemList[index].title, 0, 0,  "Times New Roman", 12)

	rowText.anchorX = 0.5
	rowText.anchorY = 0.5
	rowText.x = SCREEN_WIDTH *0.5
	rowText.y = ROW_HEIGHT * 0.5
	rowText:setFillColor( 0.1, 0.1, 0.1 )

end
	

local function onRowTouch( event )

end


local function scrollListener( event )
	
   return true
end


local function insertTable()
	for i = 1, 100 do
		list:insertRow{
				rowHeight =ROW_HEIGHT,
				rowColor = {  default = { 1, 1, 1 }, over = { 0.95, 0.95, 0.95, 1 }},
				}		
	end
end


function reloadTable(index, count, slideDirection)

	if (list:getNumRows() < index) then
		print("Cannot insert at "..index..". Table too small.")
		return
	end	

	local rowOptionList = {}
	
	for i = count, 1, -1 do
	-- Fetch the new rows!!!	
		local newRow = {}
		newRow.title = "Title - insert ("..os.clock()..")"	
		table.insert(itemList, index, newRow)

		rowOptionList[i]	=		{
				rowHeight =ROW_HEIGHT,
				rowColor = {  default = { 1, 1, 1 }, over = { 0.95, 0.95, 0.95, 1 }}
				}
		
	end

		local function insertComplete()
			print("INSERT COMPLETE...Safe to do another insert/delete...")
			--		list:reloadData()
		end
	
	list:insertRowsAtIndex( index, rowOptionList, {insertDirection = slideDirection, onComplete = insertComplete})
		
end


function deleteFromTable(startRowIndex, endRowIndex)
	
	if (list:getNumRows() < endRowIndex) then
		print("not enough rows...")
		return
	end
	
	local function deleteComplete()
		print("DELETE COMPLETE...Safe to do another insert/delete...")
		
		-- VERY IMPORTANT: The data model for the tableview should be updated only in this callback.
		-- Otherwise, if it is done before calling deleteRowsAtIndex(), then the deletion animation
		-- will use the updated data model for its transition animation  causing issues.
		
		for i = startRowIndex, endRowIndex do
			table.remove(itemList, startRowIndex)
		end	
		--	list:reloadData()
	end
	
	list:deleteRowsAtIndex( startRowIndex, endRowIndex, {transitionTime =350, onComplete = deleteComplete} )
	
end


local function createWidgets()		
	toolbar = display.newImage( "toolbar.png")	
	toolbar.xScale = SCREEN_WIDTH / toolbar.contentWidth
	toolbar.anchorX = 0
	toolbar.anchorY = 0
	toolbar.x, toolbar.y = 0, 0

	list = widget.newTableView{
		top = toolbar.contentHeight,
		height = SCREEN_HEIGHT - toolbar.contentHeight,
		maxVelocity = 1, 
		noLines = false,
		onRowRender = onRowRender,
		onRowTouch = onRowTouch,
		listener = scrollListener
	}
		
	insertLeftButton = widget.newButton
	{
	    id = "insertLeft",
	    left = 2,
	    top = 2,
	    label = "Insert Left",
		labelAlign = "center",
		fontSize = 12,
	    width = 70, height = toolbar.contentHeight - 4,
	    cornerRadius = 4,
		onRelease = function() 
								reloadTable(3, 2, "left")
							end;
	}

	insertLeftButton.anchorX = 0
	insertLeftButton.anchorY = 0.5
	insertLeftButton.x = 5
	insertLeftButton.y = toolbar.contentHeight *0.5

	insertRightButton = widget.newButton
	{
	    id = "insertRight",
	    left = 2,
	    top = 2,
	    label = "Insert Right",
		labelAlign = "center",
		fontSize = 12,
	    width = 70, height = toolbar.contentHeight - 4,
	    cornerRadius = 4,
		onRelease = function() 
								reloadTable(3, 2, "right")
							end;
	}

	insertRightButton.anchorX = 0
	insertRightButton.anchorY = 0.5
	insertRightButton.x = 80
	insertRightButton.y = toolbar.contentHeight *0.5


	insertDownButton = widget.newButton
	{
	    id = "insertDown",
	    left = 2,
	    top = 2,
	    label = "Insert Down",
		labelAlign = "center",
		fontSize = 12,
	    width = 70, height = toolbar.contentHeight - 4,
	    cornerRadius = 4,
		onRelease = function() 
								reloadTable(3, 2, "down")
							end;
	}

	insertDownButton.anchorX = 0
	insertDownButton.anchorY = 0.5
	insertDownButton.x = 150
	insertDownButton.y = toolbar.contentHeight *0.5



	deleteButton = widget.newButton
	{
	    id = "Delete",
	    left = 2,
	    top = 2,
	    label = "Delete",
		labelAlign = "center",
		fontSize = 12,
	    width = 70, height = toolbar.contentHeight - 4,
	    cornerRadius = 4,
		onRelease = function() 
								deleteFromTable(4,15)
							end;
	}

	deleteButton.anchorX = 0
	deleteButton.anchorY = 0.5
	deleteButton.x = 220
	deleteButton.y = toolbar.contentHeight *0.5

end



local function onRequireWidgetLibrary(name)
	return require("widgetLibrary." .. name)
end
package.preload.widget = onRequireWidgetLibrary
package.preload.widget_button = onRequireWidgetLibrary
package.preload.widget_momentumScrolling = onRequireWidgetLibrary
package.preload.widget_pickerWheel = onRequireWidgetLibrary
package.preload.widget_progressView = onRequireWidgetLibrary
package.preload.widget_scrollview = onRequireWidgetLibrary
package.preload.widget_searchField = onRequireWidgetLibrary
package.preload.widget_segmentedControl = onRequireWidgetLibrary
package.preload.widget_spinner = onRequireWidgetLibrary
package.preload.widget_stepper = onRequireWidgetLibrary
package.preload.widget_slider = onRequireWidgetLibrary
package.preload.widget_switch = onRequireWidgetLibrary
package.preload.widget_tabbar = onRequireWidgetLibrary
package.preload.widget_tableview = onRequireWidgetLibrary


display.setStatusBar( display.HiddenStatusBar )	
createWidgets()
initData(100)

