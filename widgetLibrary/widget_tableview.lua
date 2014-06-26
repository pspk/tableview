-- Copyright © 2013 Corona Labs Inc. All Rights Reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of the company nor the names of its contributors
--      may be used to endorse or promote products derived from this software
--      without specific prior written permission.
--    * Redistributions in any form whatsoever must retain the following
--      acknowledgment visually in the program (e.g. the credits of the program): 
--      'This product includes software developed by Corona Labs Inc. (http://www.coronalabs.com).'
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL CORONA LABS INC. BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

local M = 
{
	_options = {},
	_widgetName = "widget.newtableView",
}


-- Require needed widget files
local _widget = require( "widget" )
local _momentumScrolling = require( "widget_momentumScrolling" )

local isGraphicsV1 = ( 1 == display.getDefault( "graphicsCompatibility" ) )

-- Localize math functions
local mAbs = math.abs


--   removes all contents recursively. Used ONLY on display groups!!!
local function cleanNestedDisplayGroups ( objectOrGroup )
	if objectOrGroup.numChildren then
		while objectOrGroup.numChildren > 0 do
			cleanNestedDisplayGroups( objectOrGroup[objectOrGroup.numChildren])
		end
    end    
	display.remove(objectOrGroup)
	objectOrGroup = nil
    return
end


-- Creates a new tableView
local function createTableView( tableView, options )
	-- Create a local reference to our options table
	local opt = options
	
	-- Forward references
	local view, viewBackground, viewMask, viewFixed, categoryGroup

	-- Create the view
	view = display.newGroup()

	view.x = - opt.width * 0.5
	if isGraphicsV1 then
		view.y = - opt.height * 0.5
	end
	
	-- Create the fixed view
	viewFixed = display.newGroup()
		
	-- Create the view's background
	local bgPositionX = 0
	local bgPositionY = 0
	if isGraphicsV1 then
		bgPositionX = - opt.width * 0.5
		bgPositionY = - opt.height * 0.5		
	end
	viewBackground = display.newRect( tableView, bgPositionX, bgPositionY, opt.width, opt.height )
	
	-- Create the view's category group
	categoryGroup = display.newGroup()
	if not isGraphicsV1 then
		--categoryGroup.anchorX = 0; categoryGroup.anchorY = 0
	end
	
	----------------------------------
	-- Properties
	----------------------------------
	
	-- Background
	viewBackground.isVisible = not opt.shouldHideBackground
	viewBackground.isHitTestable = true
	viewBackground:setFillColor( unpack( opt.backgroundColor ) )
	
	-- Set the view's initial position ( to account for top padding )
	view.y = view.y + opt.topPadding

	-------------------------------------------------------
	-- Assign properties to the view
	-------------------------------------------------------
	
	-- We need to assign these properties to the object
	view._background = viewBackground
	view._mask = viewMask
	view._startXPos = 0
	view._startYPos = 0
	view._prevXPos = 0
	view._prevYPos = 0
	view._prevX = 0
	view._prevY = 0
	view._delta = 0
	view._velocity = 0
	view._prevTime = 0
	view._lastTime = 0
	view._tween = nil
	view._left = opt.left
	view._top = opt.top
	view._origtop = opt.top -- save for deleteRowAtIndex
	view._width = opt.width
	view._height = opt.height
	view._topPadding = opt.topPadding
	view._bottomPadding = opt.bottomPadding
	view._leftPadding = opt.leftPadding
	view._rightPadding = opt.rightPadding
	view._moveDirection = nil
	view._isHorizontalScrollingDisabled = opt.isHorizontalScrollingDisabled
	view._isVerticalScrollingDisabled = opt.isVerticalScrollingDisabled
	view._listener = opt.listener
	view._friction = opt.friction or 0.972
	view._maxVelocity = opt.maxVelocity or 2
	view._timeHeld = 0
	view._isLocked = opt.isLocked
	-- allow row touch if the view is moving
	view._permitRowTouches = false
	view._hideScrollBar = opt.hideScrollBar
	view._rows = {}
	view._rowWidth = opt.rowWidth
	view._rowHeight = opt.rowHeight
	view._noLines = opt.noLines
	view._currentCategoryIndex = 0
	view._hasRenderedRows = false
	view._onRowRender = opt.onRowRender
	view._onRowTouch = opt.onRowTouch
	view._scrollHeight = 0
	view._trackVelocity = false	
	view._updateRuntime = false
	view._numberOfRows = 0
	view._rowTouchDelay = opt.rowTouchDelay
	-- set the passed theme params on the view
	view._themeParams = opt.themeParams
	
	-- assign the momentum property
	view.scrollStopThreshold = opt.scrollStopThreshold
	view.isBounceEnabled = opt.isBounceEnabled
	view.autoHideScrollBar = opt.autoHideScrollBar
	view._widgetType = "tableView"
		
	-------------------------------------------------------
	-- Assign properties/objects to the tableView
	-------------------------------------------------------
	
	-- Assign objects to the view
	view._categoryGroup = categoryGroup
	view._fixedGroup = viewFixed
	
	-- Assign objects to the tableView
	tableView._view = view
	tableView:insert( view )
	tableView:insert( categoryGroup )
	tableView:insert( viewFixed )
	
	----------------------------------------------------------
	--	PUBLIC METHODS	
	----------------------------------------------------------
	
	-- Function to insert a row into a tableView
	function tableView:insertRow( options )
		return self._view:_insertRow( options )
	end
	
	-- Function to insert multiple rows into a tableView at a specific index
	function tableView:insertRowsAtIndex( index, rowOptionList, options )
		return view:_insertRowsAtIndex( index, rowOptionList, options )
	end
	
	-- Function to delete a row from a tableView
	function tableView:deleteRow( rowIndex, params ) 
		return self._view:_deleteRow( rowIndex, params ) 
	end
	
	-- Function to delete a set of rows from a tableView at a specific index
	function tableView:deleteRowsAtIndex( startRowIndex, endRowIndex, options ) 
		return self._view:_deleteRowsAtIndex( startRowIndex, endRowIndex, options)	
	end		
		
	-- Function to delete all rows from a tableView
	function tableView:deleteAllRows()
		return self._view:_deleteAllRows()
	end
	
	-- Function to scroll the tableView to a specific row
	function tableView:scrollToIndex( ... )
		return self._view:_scrollToIndex( ... )
	end
	
	-- Function to scroll the tableView to a specific y position
	function tableView:scrollToY( options )
		return self._view:_scrollToY( options )
	end
	
	-- Function to retrieve the x/y position of the tableView's content
	function tableView:getContentPosition()
		return self._view.y
	end

	-- Function to retrieve the number of rows in a tableView
	function tableView:getNumRows()
		return self._view._numberOfRows
	end
	
	-- Function to retrieve the row (view) at the specific index
	function tableView:getRowAtIndex( index )
		return self._view:_getRowAtIndex( index )
	end
	
	-- Function to reload tableView data
	function tableView:reloadData()
		return self._view:_reloadData()
	end
	
	-- isLocked setter function
	function tableView:setIsLocked( lockedState )
		return self._view:_setIsLocked( lockedState )
	end
	
	----------------------------------------------------------
	--	PRIVATE METHODS	
	----------------------------------------------------------
	
	-- Override scale function as tableView's don't support it
	function tableView:scale()
		print( M._widgetName, "Does not support scaling" )
	end
	
	-- Override the insert method for tableView to insert into the view instead
	tableView._cachedInsert = tableView.insert

	function tableView:insert( arg1, arg2 )
		local index, obj
		
		if arg1 and type(arg1) == "number" then
			index = arg1
		elseif arg1 and type(arg1) == "table" then
			obj = arg1
		end
		
		if arg2 and type(arg2) == "table" then
			obj = arg2
		end
		
		if index then
			self._view:insert( index, obj )
		else
			self._view:insert( obj )
		end
	end
	
	-- Transfer touch from the view's background to the view's content
	function viewBackground:touch( event )
		view:touch( event )
		
		return true
	end
	
	viewBackground:addEventListener( "touch" )
	
	-- Private Function to get a row at a specific y position
	function view:_getRowAtPosition( position )
		local yPosition = position
		
		for k, v in pairs( self._rows ) do
			local currentRow = self._rows[k]
			
			-- If the current row exists on screen
			if "table" == type( currentRow._view ) then
				local bounds = currentRow._view.contentBounds
				
				local isWithinBounds = yPosition >= bounds.yMin and yPosition <= bounds.yMax + 1
				-- If we have hit the bottom limit, return the first row
				if self._hasHitBottomLimit then
					return self._rows[1]._view
				end
			
				-- If we have hit the top limit, return the last row
				if self._hasHitTopLimit then
					return self._rows[#self._rows]._view
				end
			
				-- If the row is within bounds
				if isWithinBounds then
					local translateToPos = - currentRow.y - self.parent.y - 6
					if isGraphicsV1 then
						translateToPos = - currentRow.y - self.parent.y
					end								
					transition.to( self, { time = 280, y = translateToPos, transition = easing.outQuad } )
					
					return currentRow._view
				end
			end
		end
	end
	
	function view:_getRowAtIndex( index )
		local currentIndex = index
		local currentRow = self._rows[currentIndex]

		return currentRow._view
	
	end


	function view:_getIndexOfView(  )	
		local accumHeight = 0
		local curRow =nil
		for i = 1, table.maxn(self._rows) do							
			accumHeight = accumHeight + self._rows[i]._height	
			if accumHeight > -(self.y) then
				curRow = i
				break
			end 
		end		
		return curRow								
	end		
	
	-- Checks if row is within the upperLimit (table view top) and lowerLimit (table view bottom)
	-- offsets can be provided to expand the upper and lower limits
	function view:_isRowWithinBounds(row, upperOffset, lowerOffset)				
		local upperLimit = self._background.y - ( self._background.contentHeight * 0.5 )
		local lowerLimit = self._background.y + ( self._background.contentHeight * 0.5 )
		-- Is this row within the visible bounds of our view?
		return ( row.y + self.y ) + row._height  > upperLimit - upperOffset and ( row.y + self.y ) - row._height * 2 < lowerLimit  + lowerOffset
	end
	
	-- Handle touches on the tableView
	function view:touch( event )
		local phase = event.phase

		-- the event.target is the tableView row. however, the row has calculations in the enterFrame listener that prevent the table from scrolling
		-- when the limit is hit. In this case, only if the view is used in picker, we set the target to the tableview's background, and that will allow
		-- free movement independently.
		if self._isUsedInPickerWheel then
			event.target = view._background
		end
		
		-- Set the time held
		if "began" == phase then
			self._timeHeld = event.time
			
			-- Set the initial touch
			if not self._initalTouch then
				self._initialTouch = true
			end
			
			-- By default we allow touch events for our rows
			self._permitRowTouches = true
			
			-- If the velocity is over 0.05, we prevent touch events on the rows as press/tap events should only result in the view's momentum been stopped
			if mAbs( self._velocity ) > 0.05 then
				-- if the view is at the bottom or at the top, allow the touch, because in the momentum we have a timer that causes the above if 
				-- to determine that the view is still in motion, although it's not.
				if not self._hasHitBottomLimit and not self._hasHitTopLimit then
					self._permitRowTouches = false
				else
					self._velocity = 0
				end
			end	
			
			if self._isUsedInPickerWheel then
				for i = 1, #self._rows do
					-- if the row is on screen, set it to the default color
					if nil ~= self._rows[ i ]._view then
						self._rows[ i ]._view[ 2 ]:setFillColor( unpack( self._themeParams.colours.pickerRowColor ) )
					end
				end
			end
					
		end	
		
		-- Distance moved
		local dy = mAbs( event.y - event.yStart )
		local moveThresh = 20
		
		if "moved" == phase and not self._isUsedInPickerWheel then
			if dy < moveThresh and self._initialTouch then
				if event.phase ~= "ended" and event.phase ~= "cancelled" then
					event.phase = "began"
				end
			else
				-- This wasn't the initial touch
				self._initialTouch = false
				-- New phase is now nil, since it was moved
				self._newPhase = nil
				
				if "table" == type( self._targetRow ) then
					if "table" == type( self._targetRow._cell ) then
						-- If the row isn't a category
						if not self._targetRow.isCategory then
							if self._targetRow._wasTouched then
								-- Set the row cell's fill color
								self._targetRow._cell:setFillColor( unpack( self._targetRow._rowColor.default ) )
								-- Set back the separators
								if self._targetRow._separator then
									self._targetRow._separator.isVisible = true
								end
								if view._rows[ self._targetRow.index - 1 ] then
									if view._rows[ self._targetRow.index - 1 ]._view._separator then
										view._rows[ self._targetRow.index - 1 ]._view._separator.isVisible = true
									end
								end
								-- The row was no longer touched
								self._targetRow._wasTouched = false
							
								-- Setup a cancelled event for this row
								local newEvent =
								{
									phase = "cancelled",
									target = event.target,
									row = self._targetRow,
								}
							
								-- Execute the row's touch event 
								self._onRowTouch( newEvent )
							end
						end
					end
				end
			end
		end
		
		-- Set the view's phase so we can access it in the enterFrame listener below
		self._phase = event.phase
		
		-- Handle momentum scrolling (if the view isn't locked)
		if not self._isLocked then
			_momentumScrolling._touch( self, event )
		end
				
		-- Execute the listener if one is specified
		if "function" == type( self._listener ) then
			self._listener( event )
		end
		
		-- Set the view's target row (the row we touched) so we can access it in the enterFrame listener below
		self._targetRow = event.target
		
		-- Handle swipe events on the tableView
		-- TODO: removed "moved" == phase from the if, which made swipe events to be propagated instantly, instead of at the end phase.
		-- This conflicted however with the ability to tap, hold and then scroll the tableview
		if "ended" == phase or "cancelled" == phase then
			-- This wasn't the initial touch
			self._initialTouch = false
			
			if mAbs( self._velocity ) < 0.01 then
				local xStart = event.xStart
				local xEnd = event.x
				local yStart = event.yStart
				local yEnd = event.y
				local minSwipeDistance = 50

				local xDistance = mAbs( xEnd - xStart )
				local yDistance = mAbs( yEnd - yStart )

				-- Horizontal Swipes
				if xDistance > yDistance then
					if xStart > xEnd then
						if ( xStart - xEnd ) > minSwipeDistance then
							local newEvent =
							{
								phase = "swipeLeft",
								target = event.target,
								row = self._targetRow,
							}
							if self._onRowTouch then
								self._onRowTouch( newEvent )
							end
						end
					else
						if ( xEnd - xStart ) > minSwipeDistance then
							local newEvent =
							{
								phase = "swipeRight",
								target = event.target,
								row = self._targetRow,
							}
							if self._onRowTouch then
								self._onRowTouch( newEvent )
							end
						end
					end
				end
			end
		end
			
		-- If the previous phase was a press event, dispatch a release event
		if "press" == self._newPhase and not self._initialTouch then
			if self._onRowTouch then
				local newEvent =
				{
					phase = "release",
					target = event.target,
					row = self._targetRow,
				}
				
				-- Set the row cell's fill color, if the row's view still exists (not being deleted)
				if self._targetRow._cell then
					self._targetRow._cell:setFillColor( unpack( self._targetRow._rowColor.default ) )
					if self._targetRow._separator then
						self._targetRow._separator.isVisible = true
					end
					if view._rows[ self._targetRow.index - 1 ] and view._rows[ self._targetRow.index - 1 ]._view then 
						if view._rows[ self._targetRow.index - 1 ]._view._separator then
							view._rows[ self._targetRow.index - 1 ]._view._separator.isVisible = true
						end
					end
				end
				
				-- Execute the row's touch event 
				self._onRowTouch( newEvent )
				
				-- Set the phase to none
				self._newPhase = nil
				
				-- This wasn't the initial touch
				self._initialTouch = false
				
				-- The row shouldn't allow a tap event at this time
				self._targetRow._cannotTap = true
				
				-- This row was touched
				self._targetRow._wasTouched = false
			end
		end
			
		return true
	end
	
	view:addEventListener( "touch" )
	
		
	-- EnterFrame listener for our tableView
	function view:enterFrame( event )
		
		local _tableView = self.parent
		
		-- If we have finished rendering all rows
		if self._hasRenderedRows then			
			-- Create the scrollBar
			if not self._hideScrollBar then
				if not self._scrollBar and not self._isLocked and not self._scrollBar then
					self._scrollBar = _momentumScrolling.createScrollBar( view, opt.scrollBarOptions )
				end
			end
			
			-- If the calculated scrollHeight is less than the height of the tableView, set it to that.
			if "number" == type( self._scrollHeight ) then
				if not self._isUsedInPickerWheel then
					if self._scrollHeight < self._height then
						self._scrollHeight = self._height
					end
				end
			end

			-- Set the renderedRows back to false
			self._hasRenderedRows = false
		end
		
		-- Handle momentum @ runtime
		_momentumScrolling._runtime( self, event )
		
		-- Calculate the time the touch was held
		local timeHeld = event.time - self._timeHeld
				
		-- Dispatch the "press" phase
		if "began" == self._phase and self._initialTouch and not self._targetRow._wasTouched then
			-- Reset any velocity
			self._velocity = 0
			
			-- If there is a onRowTouch listener
			if self._onRowTouch then
				-- If the row isn't a category
				if nil ~= self._targetRow.isCategory then
					-- The row can allow tap's again
					self._targetRow._cannotTap = false
				end
			end
			
			-- If a finger was held down
			if timeHeld >= self._rowTouchDelay then				
				-- If there is a onRowTouch listener
				if self._onRowTouch and self._permitRowTouches then
					-- If the row isn't a category
					if nil ~= self._targetRow.isCategory then
						self._newPhase = "press"
						local newEvent =
						{
							phase = "press",
							target = self._targetRow,
							row = self._targetRow,
						}
				
						-- Set the row cell's fill color
						self._targetRow._cell:setFillColor( unpack( self._targetRow._rowColor.over ) )
						if self._targetRow._separator then
							self._targetRow._separator.isVisible = false
						end

						if view._rows[ self._targetRow.index - 1 ] and view._rows[ self._targetRow.index - 1 ]._view then  
							if view._rows[ self._targetRow.index - 1 ]._view._separator then
								view._rows[ self._targetRow.index - 1 ]._view._separator.isVisible = false
							end
						end
				
						-- Execute the row's onRowTouch listener
						self._onRowTouch( newEvent )
						
						self._targetRow._wasTouched = true							
					end
				
					-- Set the phase to nil
					self._phase = nil
									
					-- Reset the time held
					timeHeld = 0
				end
			end
		end
				
		-- Manage all row's lifeCycle
		self:_manageRowLifeCycle()
		
		-- Constrain x/y scale values to 1.0
		if _tableView.xScale ~= 1.0 then
			_tableView.xScale = 1.0
			print( M._widgetName, "Does not support scaling" )
		end
		
		if _tableView.yScale ~= 1.0 then
			_tableView.yScale = 1.0
			print( M._widgetName, "Does not support scaling" )
		end
		
		-- Update the top position of the tableView (if moved)
		if _tableView.y ~= self._top then
			self._top = _tableView.y
		end
		
		return true
	end
	
	Runtime:addEventListener( "enterFrame", view )	
	
	-- suspend / resume listener
	-- this is for Android devices. Looks like the touch listener "dies" after the device goes in standby and back a number of times
	-- it looks like the listener seems to be in a bad state.
	-- this is a hack.

	local function _handleSuspendResume( event )
		-- if the application comes back from a suspension
		if "applicationResume" == event.type then
			if Runtime._tableListeners.enterFrame then
				for _,func in pairs(Runtime._tableListeners.enterFrame) do
					if func==view then
						Runtime:removeEventListener( "enterFrame", view )
					end
				end
			end
			Runtime:addEventListener( "enterFrame", view )
		end
	end
	
	Runtime:addEventListener("system", _handleSuspendResume)	

		
	-- Function to set all tableView categories (if any)
	function view:_gatherCategories()
		local categories = {}
		local numCategories = 0
		local firstCategory = 0
		local previousCategory = 0
		
		-- Loop through all rows and set categories
		for i = 1, #self._rows do
			local currentRow = self._rows[i]
			
			-- added a check for currentRow because this method can get called while deleting a row, so we have a race condition.
			if currentRow and currentRow.isCategory then
				if not previousCategory then
					categories["cat-" .. i] = "first"
					previousCategory = i
					numCategories = numCategories + 1
				else
					categories["cat-" .. i] = previousCategory
					previousCategory = i
					numCategories = numCategories + 1
				end
				
				-- Store reference to first category index
				if not firstCategory then
					firstCategory = i
				end
			end
		end
		
		-- Assign some category variables to the view
		self._firstCategoryIndex = firstCategory
		
		-- Return the gathered categories table
		return categories, numCategories
	end


	-- Function to render a category
	function view:_renderCategory( row )
		-- Create a reference to the row
		local currentRow = row
		
		-- Function to create a new category
		local function newCategory()
			local category = display.newGroup()
			if not isGraphicsV1 then
				category.anchorX = 0; category.anchorY = 0
			end
			
			-- get the padding values
			local leftPadding = self._themeParams.separatorLeftPadding
			local rightPadding = self._themeParams.separatorRightPadding
			
			-- Create the row's cell
			local rowCell = display.newRect( category, 0, 0, currentRow._width, currentRow._height )
			local rowCellX = rowCell.contentWidth * 0.5
			if isGraphicsV1 then
				rowCellX = 0
			end
			rowCell.x = rowCellX
			rowCell.y = rowCell.contentHeight * 0.5
			rowCell:setFillColor( unpack( currentRow._rowColor.default ) )
			
			-- If the user want's lines between rows, create a line to separate them
			if not currentRow._noLines and not currentRow.isCategory then
				-- Create the row's dividing line
				local rowLine 
				
				rowLine = display.newLine( category, 0, rowCell.y, currentRow._width, rowCell.y )

				if isGraphicsV1 then
					rowLine:setReferencePoint( display.CenterReferencePoint )
				else
					rowLine.anchorX = 0.5; rowLine.anchorY = 0.5
				end
				rowLine.x = 0
				rowLine.y = rowCell.y + ( rowCell.contentHeight * 0.5 ) + 0.5
				rowLine:setStrokeColor( unpack( currentRow._lineColor ) )					
			end

			-- Set the row's id
			category.id = currentRow.id
			
			-- Reset the params, if they were set
			category.params = currentRow.params
			
			-- Set the categories index
			category.index = currentRow.index
			
			-- Set the category as a category
			category.isCategory = true
			
			-- Ensure the stuck category doesn't leak touch events to rows below it
			category:addEventListener( "touch", function() return true end )
			category:addEventListener( "tap", function() return true end )
			
			-- Insert the category into the group
			local catGroupY = - self.parent.height * 0.5 - category.contentHeight * 0.5
			if isGraphicsV1 then
				catGroupY = - self.parent.height * 0.5
			else
				rowCell.anchorX = 0.5; rowCell.anchorY = 0.5
			end
			self._categoryGroup.y = catGroupY
			local rowX = 0
			self._categoryGroup.x = rowX
			self._categoryGroup:insert( category )
			
			return category
		end
					
		-- Function to create a new category
		local function initNewCategory()			
			-- If there is already a category rendered, remove it
			if self._currentCategory then
				display.remove( self._currentCategory )
				self._currentCategory = nil
			end
						
			-- Create the category
			self._currentCategory = newCategory()
			if isGraphicsV1 then
				self._currentCategory:setReferencePoint( display.CenterReferencePoint )
			else
				self._currentCategory.anchorX = 0.5; self._currentCategory.anchorY = 0.5
			end
			local catX = self.x
			if isGraphicsV1 then
				catX = catX + self.parent.width * 0.5
			end
			self._currentCategory.x = catX
			self._currentCategory.y = self._currentCategory.contentHeight * 0.5
			
			-- Create the rowRender event
			local rowEvent = 
			{
				name = "rowRender",
				row = self._currentCategory,
				target = self.parent,
			}

			-- If an onRowRender event exists, execute it
			if self._onRowRender and "function" == type( self._onRowRender ) then
				self._onRowRender( rowEvent )
			end
		end
		
		-- If there is currently no category rendered
		if not self._currentCategory then 
			initNewCategory()
		else
			if self._currentCategory.index ~= currentRow.index then
				initNewCategory()
			end
		end		
	end
	
		
	-- Function to manage all row's lifeCycle
	function view:_manageRowLifeCycle()
		
		-- Gather all tableView categories
		if "table" ~= type( self._categories ) then
			self._categories, self._numCategories = self:_gatherCategories()
		end
		
		-- Ensure that the category is stuck in the correct position
		if self._currentCategory and self._currentCategory.y ~= self._currentCategory.contentHeight * 0.5 then
			self._currentCategory.y = self._currentCategory.contentHeight * 0.5
		end
										
		-- Set the upper and lower category limits
		local upperLimit = self._background.y - ( self._background.contentHeight * 0.5 )
		local lowerLimit = self._background.y + ( self._background.contentHeight * 0.5 )
		
		-- Create a local reference to our categories
		local categories = self._categories
				
		-- Loop through all of the rows contained in the tableView 
		for k, v in pairs( self._rows ) do
			local currentRow = self._rows[k]
			
			-- If this row's view property doesn't exist
			if type( currentRow._view ) ~= "table" then
				-- Is this row within the visible bounds of our view?				
--				local isRowWithinBounds = ( currentRow.y + self.y ) + currentRow._height > upperLimit and ( currentRow.y + self.y ) - currentRow._height * 2 < lowerLimit
				local isRowWithinBounds = ( currentRow.y + self.y ) + currentRow._height * 2 > upperLimit and ( currentRow.y + self.y ) - currentRow._height * 2 < lowerLimit
				
				-- If this row is within bounds, create it
				if isRowWithinBounds then
					self:_createRow( currentRow, true )
				end
			end
			
			-- Manage tableView categories (if there are any)
			if self._numCategories > 0 then
				-- If the currrent row has a view
				if type( currentRow._view ) == "table" then			
					-- Set the rows top position
					local rowTop = self.y + currentRow._view.y + view._height * 0.5
					if isGraphicsV1 then
						rowTop = self.y + currentRow._view.y - currentRow._view.contentHeight * 0.5 + self.parent.height * 0.5
					end
					currentRow._top = rowTop
							
					-- Category "pushing" effect
					if self._currentCategory and currentRow.isCategory and currentRow.index ~= self._currentCategory.index then
						if currentRow._top < self._currentCategory.contentHeight and currentRow._top >= 0 then
							-- Push the category upward
							if self._currentCategory then
								self._currentCategory.y = currentRow._top - ( self._currentCategory.contentHeight * 0.5  )
							end
						end
					end
										
					-- Determine which category should be rendered (Sticky category at top)
					if currentRow.isCategory and currentRow._top <= 0 then
						self._currentCategoryIndex = k
						
						-- Hide the current row
						currentRow._view.isVisible = false
						
					elseif currentRow.isCategory and currentRow._top >= 0 and self._currentCategory and currentRow.index == self._currentCategory.index then
						-- Category moved below top of tableView, render previous category
						currentRow._view.isVisible = true
												
						-- Remove current category if the first category moved below the top of the tableView
						display.remove( self._currentCategory )
						self._currentCategory = nil
						self._currentCategoryIndex = nil
					elseif currentRow.isCategory and currentRow._top >= 0 then
						currentRow._view.isVisible = true
					end
				end	
			end
			
			-------------------------
			-- Handle row culling
			-------------------------
			
			-- Is this row currently within the tableView bounds ? Or above or below it.
			if "table" == type( currentRow._view ) then
				-- Is this row within the visible bounds of our view?
				local isRowWithinBounds = ( currentRow.y + self.y ) + currentRow._height * 2 > upperLimit and ( currentRow.y + self.y ) - currentRow._height * 2 < lowerLimit
				
				-- If this row is a category, change the boundary to reflect it
				if currentRow.isCategory then
					isRowWithinBounds = ( currentRow.y + self.y ) - currentRow._height < lowerLimit
				end
				
				-- Remove rows that are are currently not within our view's visible bounds
				if not isRowWithinBounds then
					-- Remove this row
					cleanNestedDisplayGroups(currentRow._view) 
					currentRow._view = nil					
				end
			end
		end
		
		-- Render current category (if there are any categories)
		if self._numCategories > 0 then
			if self._currentCategoryIndex and self._currentCategoryIndex > 0 then
				self:_renderCategory( self._rows[self._currentCategoryIndex] )
			end
		end
	end
	
	-- Send row touch event's to the view
	local function _handleRowTouch( event )
		local phase = event.phase
		
		view:touch( event )

		return true
	end
	
	
	-- Handle tap events on the row
	local function _handleRowTap( event )
		local row = event.target
		
		-- If tap's are allowed on the row at this time
		if not row._cannotTap and view._permitRowTouches then
			if "function" == type( view._onRowTouch ) then
				local newEvent =
				{
					phase = "tap",
					target = row,
				}

				-- Set the row cell's fill color
				row._cell:setFillColor( unpack( row._rowColor.over ) )
				if row._separator then
					row._separator.isVisible = false
				end

				if view._rows[ row.index - 1 ] and view._rows[ row.index - 1 ]._view then 
					if view._rows[ row.index - 1 ]._view._separator then    
						view._rows[ row.index - 1 ]._view._separator.isVisible = false
					end
				end
		
				-- After a little delay, set the row's fill color back to default
				--timer.performWithDelay( 100, function()
					-- Set the row cell's fill color
					row._cell:setFillColor( unpack( row._rowColor.default ) )
					if row._separator then
						row._separator.isVisible = true
					end

					if view._rows[ row.index - 1 ] and view._rows[ row.index - 1 ]._view then 
						if view._rows[ row.index - 1 ]._view._separator then
							view._rows[ row.index - 1 ]._view._separator.isVisible = true
						end
					end
				--end)

				-- Execute the row's onRowTouch listener
				view._onRowTouch( newEvent )
			end
		end
	end
	
	
	-- Function to create a tableView row
	function view:_createRow( row, isReRender )
		
		local currentRow = row
		
		-- Set the upper and lower category limits
		local upperLimit = self._background.y - ( self._background.contentHeight * 0.5 )
		local lowerLimit = self._background.y + ( self._background.contentHeight * 0.5 )
		-- Is this row within the visible bounds of our view?
--		local isRowWithinBounds = ( currentRow.y + self.y ) + currentRow._height > upperLimit and ( currentRow.y + self.y ) - currentRow._height * 2 < lowerLimit  
		local isRowWithinBounds = ( currentRow.y + self.y ) + currentRow._height * 2 > upperLimit and ( currentRow.y + self.y ) - currentRow._height * 2 < lowerLimit  
	
		-- If the row is within the bounds of the view, create it
		if isRowWithinBounds then
			-- If the row's view property doesn't exist			
			if isReRender then
					if currentRow._view then 
						cleanNestedDisplayGroups(currentRow._view) 
						currentRow._view = nil
					end
			end
			
			if type( currentRow._view ) ~= "table" then -- view existance check?

				-- We haven't finished rendering all rows yet
				self._hasRenderedRows = false
								
				-- Create the row's view (a row is a display group)
				currentRow._view = display.newGroup()
				
				-- Create the row's cell
				local rowCell = display.newRect( currentRow._view, 0, 0, currentRow._width, currentRow._height ) 
				rowCell.x = rowCell.contentWidth * 0.5
				rowCell.y = rowCell.contentHeight * 0.5
				rowCell:setFillColor( unpack( currentRow._rowColor.default ) )
				rowCell.isHitTestable = true
				
				-- if graphics 2.0, anchor the row cell to 0.5 / 0.5
				if not isGraphicsV1 then
					rowCell.anchorX = 0.5; rowCell.anchorY = 0.5
				end

				-- If the user want's lines between rows, create a line to seperate them
				if not self._noLines and not currentRow.isCategory then
					-- Create the row's dividing line
					local rowLine 
					local leftPadding = view._themeParams.separatorLeftPadding
					local rightPadding = view._themeParams.separatorRightPadding
					
					rowLine = display.newRect( currentRow._view, leftPadding, rowCell.y, currentRow._width - rightPadding - leftPadding, 1 )
					if isGraphicsV1 then
						rowLine:setReferencePoint( display.CenterReferencePoint )
						rowLine.x = rowCell.x + math.floor( leftPadding * 0.5 )
					else
						rowLine.anchorX = 0.5; rowLine.anchorY = 0.5
						rowLine.x = leftPadding + rowLine.contentWidth * 0.5
					end

--					rowLine.y = rowCell.y + ( rowCell.contentHeight * 0.5 ) - rowLine.contentHeight * 0.5 
					rowLine.y = rowCell.y + ( rowCell.contentHeight * 0.5 ) - rowLine.contentHeight * 0.5 
					rowLine:setFillColor( unpack( currentRow._lineColor ) )	
					
					-- assign the reference to the view
					currentRow._view._separator = rowLine				
				end
			
				-- Set the row's reference point to it's center point (just incase)
				if isGraphicsV1 then
					currentRow._view:setReferencePoint( display.CenterReferencePoint )
				else
					currentRow._view.anchorX = 0.5; currentRow._view.anchorY = 0.5
				end

				-- Position the row
				local rowX = 0
				if isGraphicsV1 then
					rowX = currentRow._width * 0.5
				end
				currentRow._view.x = rowX
		
				local curY = currentRow.y - currentRow._view.contentHeight * 0.5
				if isGraphicsV1 then
					curY = currentRow.y 
				end
				currentRow._view.y = curY

				-- Assign properties to the row
				currentRow._view._cell = rowCell
				currentRow._view._rowColor = currentRow._rowColor
				currentRow._view.index = currentRow.index
				currentRow._view.id = currentRow.id
				-- add the custom params to the row
				currentRow._view.params = currentRow.params
				currentRow._view._label = currentRow._label
				currentRow._view.isCategory = currentRow.isCategory
				
				-- Insert the row into the view
				self:insert( currentRow._view )		
				
				-- Add event listener to the row
				if not currentRow.isCategory then
					currentRow._view:addEventListener( "touch", _handleRowTouch )
					currentRow._view:addEventListener( "tap", _handleRowTap )
				else
					-- If the row is a category, pass the touch event back to the view
					local function scrollList( event )
						-- Handle momentum scrolling (if the view isn't locked)
						if not self._isLocked then
							_momentumScrolling._touch( self, event )
						end

						return true
					end

					currentRow._view:addEventListener( "touch", scrollList )
				end
				
				-- Row methods
				function currentRow._view:setRowColor( options )
					if "table" == type( options ) then
						if "table" == type( options.default ) then
							self._rowColor.default = options.default
						end
					
						if "table" == type( options.over ) then
							self._rowColor.over = options.over
						end
					else
						print( "WARNING: row:setRowColor - options table with default/over tables expected, got", type( options ) )
					end
				end
				
				-- Create the rowRender event
				local rowEvent = 
				{
					name = "rowRender",
					row = currentRow._view,
					target = self.parent,
				}

				-- If an onRowRender event exists, execute it
				if self._onRowRender and "function" == type( self._onRowRender ) then
					self._onRowRender( rowEvent )
				end

				-- We have finished rendering the rows (unless we render another, in which case this gets reset)
				self._hasRenderedRows = true
				
			end
		end
	end
	
					
	-- Function to insert a row into a tableView
	function view:_insertRow( options, reRender )
		-- Create the row
		self._rows[table.maxn(self._rows) + 1] = {}
		
		-- Are we re-rendering this row?
		local isReRender = reRender
		
		-- Import the colours definition from the theme params
		local colours = self._themeParams.colours
		
		-- Retrieve passed in row customization variables
		local rowId = options.id or table.maxn(self._rows)
		local rowIndex = table.maxn(self._rows)	
		local rowWidth = self._width
		local rowHeight = options.rowHeight or 40
		local isRowCategory = options.isCategory or false
		local rowColor = options.rowColor or colours.rowColor
		local lineColor = options.lineColor or colours.lineColor
		local noLines = self._noLines or false

		-- the passed row params
		local rowParams = options.params or {}
		-- Set defaults for row's color
		if not rowColor.default then
			rowColor.default = colours.rowColor.default
		end
		
		-- Set defaults for row's over color
		if not rowColor.over then
			rowColor.over = colours.rowColor.over
		end
		
		-- set the category colours
		if isRowCategory then
			rowColor = options.rowColor or colours.catColor
		end
		
		-- Assign public properties to the row
		self._rows[rowIndex].id = rowId
		self._rows[rowIndex].index = rowIndex
		self._rows[rowIndex].isCategory = isRowCategory
		-- add the params table to the row variable
		self._rows[rowIndex].params = rowParams
		
		-- Assign private properties to the row
		self._rows[rowIndex]._rowColor = rowColor
		self._rows[rowIndex]._lineColor = lineColor
		self._rows[rowIndex]._noLines = noLines
		self._rows[rowIndex]._width = rowWidth
		self._rows[rowIndex]._height = rowHeight
		self._rows[rowIndex]._label = options.label or ""
		self._rows[rowIndex]._view = nil

		-- increment the table rows variable
		self._numberOfRows =  self._numberOfRows + 1
		
		-- Calculate and set the row's y position
		
		if rowIndex <= 1 then
			local rowY = ( self._rows[rowIndex]._height * 0.5 ) - self.parent.height * 0.5
			if isGraphicsV1 then
				rowY = ( self._rows[rowIndex]._height * 0.5 )
			end
			self._rows[rowIndex].y = rowY
		else
			if ( self._rows[rowIndex - 1].y ) then
				self._rows[rowIndex].y = ( self._rows[rowIndex - 1].y + ( self._rows[rowIndex - 1]._height * 0.5 ) )
			 											+ ( self._rows[rowIndex]._height * 0.5 )
			end
		end
		
		-- Update the scrollHeight of our view
		self._scrollHeight = self._scrollHeight + self._rows[rowIndex]._height
		
		-- Reposition the scrollbar, if it exists
		if self._scrollBar then
			self._scrollBar:repositionY()
		end
		
		-- Create the row
		self:_createRow( self._rows[rowIndex], reRender )
		
		-- Recalculate the categories if we inserted one
		if self._rows[rowIndex].isCategory then
			self._categories, self._numCategories = self:_gatherCategories()
		end
	end
	
	
	-- Function to create a single tableView row at the given index
	function view:_createRowAtIndex( index, row , upperOffset, lowerOffset)

--TODO: CHANGE TO
--	function view:_createRowAtIndex( row )


		local currentRow = row
		
		-- Set the upper and lower category limits
		local upperLimit = self._background.y - ( self._background.contentHeight * 0.5 )
		local lowerLimit = self._background.y + ( self._background.contentHeight * 0.5 )
		-- Is this row within the visible bounds of our view?
--		local isRowWithinBounds = ( currentRow.y + self.y ) + currentRow._height > upperLimit and ( currentRow.y + self.y ) - currentRow._height * 2 < lowerLimit  
	--	local isRowWithinBounds = ( currentRow.y + self.y ) + currentRow._height * 2 > upperLimit and ( currentRow.y + self.y ) - currentRow._height * 2 < lowerLimit  
	
		local isRowWithinBounds
		if upperOffset~= nil and lowerOffset ~= nil then
			isRowWithinBounds = view:_isRowWithinBounds(currentRow, upperOffset, lowerOffset)
		else	
			isRowWithinBounds = view:_isRowWithinBounds(currentRow, 0, 0)
		end
		
		-- If the row is within the bounds of the view, create it
		if isRowWithinBounds then
			-- If the row's view property doesn't exist		
			if type( currentRow._view ) ~= "table" then 

				-- We haven't finished rendering all rows yet
				self._hasRenderedRows = false
								
				-- Create the row's view (a row is a display group)
				currentRow._view = display.newGroup()
				
				-- Create the row's cell
				local rowCell = display.newRect( currentRow._view, 0, 0, currentRow._width, currentRow._height ) 
				rowCell.x = rowCell.contentWidth * 0.5
				rowCell.y = rowCell.contentHeight * 0.5
				rowCell:setFillColor( unpack( currentRow._rowColor.default ) )
				rowCell.isHitTestable = true
				
				-- if graphics 2.0, anchor the row cell to 0.5 / 0.5
				if not isGraphicsV1 then
					rowCell.anchorX = 0.5; rowCell.anchorY = 0.5
				end

				-- If the user want's lines between rows, create a line to seperate them
				if not self._noLines and not currentRow.isCategory then
					-- Create the row's dividing line
					local rowLine 
					local leftPadding = view._themeParams.separatorLeftPadding
					local rightPadding = view._themeParams.separatorRightPadding
					
--					rowLine = display.newRect( currentRow._view, leftPadding, rowCell.y, currentRow._width - rightPadding - leftPadding, 1 )
					rowLine = display.newRect( currentRow._view, leftPadding, rowCell.y  , currentRow._width - rightPadding - leftPadding, 1 )
					
					if isGraphicsV1 then
						rowLine:setReferencePoint( display.CenterReferencePoint )
						rowLine.x = rowCell.x + math.floor( leftPadding * 0.5 )
					else
						rowLine.anchorX = 0.5; rowLine.anchorY = 0.5
						rowLine.x = leftPadding + rowLine.contentWidth * 0.5
					end

					rowLine.y = rowCell.y + ( rowCell.contentHeight * 0.5 ) - rowLine.contentHeight * 0.5
					rowLine:setFillColor( unpack( currentRow._lineColor ) )	
					
					-- assign the reference to the view
					currentRow._view._separator = rowLine				
				end
			
				-- Set the row's reference point to it's center point (just incase)
				if isGraphicsV1 then
					currentRow._view:setReferencePoint( display.CenterReferencePoint )
				else
					currentRow._view.anchorX = 0.5; currentRow._view.anchorY = 0.5
				end

				-- Position the row
				local rowX = 0
				if isGraphicsV1 then
					rowX = currentRow._width * 0.5
				end
				currentRow._view.x = rowX
			
				local curY = currentRow.y - currentRow._view.contentHeight * 0.5
				if isGraphicsV1 then
					curY = currentRow.y 
				end
				currentRow._view.y = curY
				
				-- Assign properties to the row
				currentRow._view._cell = rowCell
				currentRow._view._rowColor = currentRow._rowColor
				currentRow._view.index = currentRow.index
				currentRow._view.id = currentRow.id
				-- add the custom params to the row
				currentRow._view.params = currentRow.params
				currentRow._view._label = currentRow._label
				currentRow._view.isCategory = currentRow.isCategory
				
				-- Insert the row into the view
				self:insert( currentRow._view )		
				
				-- Add event listener to the row
				if not currentRow.isCategory then
					currentRow._view:addEventListener( "touch", _handleRowTouch )
					currentRow._view:addEventListener( "tap", _handleRowTap )
				else
					-- If the row is a category, pass the touch event back to the view
					local function scrollList( event )
						-- Handle momentum scrolling (if the view isn't locked)
						if not self._isLocked then
							_momentumScrolling._touch( self, event )
						end

						return true
					end

					currentRow._view:addEventListener( "touch", scrollList )
				end
				
				-- Row methods
				function currentRow._view:setRowColor( options )
					if "table" == type( options ) then
						if "table" == type( options.default ) then
							self._rowColor.default = options.default
						end
					
						if "table" == type( options.over ) then
							self._rowColor.over = options.over
						end
					else
						print( "WARNING: row:setRowColor - options table with default/over tables expected, got", type( options ) )
					end
				end
				
				-- Create the rowRender event
				local rowEvent = 
				{
					name = "rowRender",
					row = currentRow._view,
					target = self.parent,
				}

				-- If an onRowRender event exists, execute it
				if self._onRowRender and "function" == type( self._onRowRender ) then
					self._onRowRender( rowEvent )
				end

				-- We have finished rendering the rows (unless we render another, in which case this gets reset)
				self._hasRenderedRows = true
				
			end
		end
	end
	


	-- Function to insert multiple rows into a tableView at a specific index
	function view:_insertRowsAtIndex( index, rowOptionList, options )
	
		--disable enterFrame listener
		Runtime:removeEventListener( "enterFrame", view )	
		
		if options.insertDirection == nil then
			slideDirection = "down"
		else
			slideDirection = options.insertDirection
		end
			
		local insertGroup = display.newGroup()
		insertGroup.anchorChildren = true
		insertGroup.anchorY = 0	
		insertGroup.anchorX = 0
		
		local newRowTop = nil
		local numRows = #rowOptionList
	
		for i = 1, numRows do
			
			local options = rowOptionList[i]
			-- Create the row
			table.insert(self._rows, index+i-1, {})
				
			-- Import the colours definition from the theme params
			local colours = self._themeParams.colours
		
			-- Retrieve passed in row customization variables
			local rowId = options.id or (index + i - 1)
			local rowIndex = index + i -1 
			local rowWidth = self._width
			local rowHeight = options.rowHeight or 40
			local isRowCategory = options.isCategory or false
			local rowColor = options.rowColor or colours.rowColor
			local lineColor = options.lineColor or colours.lineColor
			local noLines = self._noLines or false

			-- the passed row params
			local rowParams = options.params or {}
			-- Set defaults for row's color
			if not rowColor.default then
				rowColor.default = colours.rowColor.default
			end
		
			-- Set defaults for row's over color
			if not rowColor.over then
				rowColor.over = colours.rowColor.over
			end
		
			-- set the category colours
			if isRowCategory then
				rowColor = options.rowColor or colours.catColor
			end

			-- Assign public properties to the row
			self._rows[rowIndex].id = rowId
			self._rows[rowIndex].index = rowIndex
			self._rows[rowIndex].isCategory = isRowCategory
			-- add the params table to the row variable
			self._rows[rowIndex].params = rowParams
		
			-- Assign private properties to the row
			self._rows[rowIndex]._rowColor = rowColor
			self._rows[rowIndex]._lineColor = lineColor
			self._rows[rowIndex]._noLines = noLines
			self._rows[rowIndex]._width = rowWidth
			self._rows[rowIndex]._height = rowHeight
			self._rows[rowIndex]._label = options.label or ""
			self._rows[rowIndex]._view = nil

			-- increment the table rows variable
			self._numberOfRows =  self._numberOfRows + 1
		
			-- Calculate and set the row's y position
		
			if rowIndex <= 1 then
				local rowY = ( self._rows[rowIndex]._height * 0.5 ) - self.parent.height * 0.5
				if isGraphicsV1 then
					rowY = ( self._rows[rowIndex]._height * 0.5 )
				end
				self._rows[rowIndex].y = rowY
			else
				if ( self._rows[rowIndex - 1].y ) then
					self._rows[rowIndex].y = ( self._rows[rowIndex - 1].y + ( self._rows[rowIndex - 1]._height * 0.5 ) )
			 												+ ( self._rows[rowIndex]._height * 0.5 )
				end
			end
					
			-- Update the scrollHeight of our view
			self._scrollHeight = self._scrollHeight + self._rows[rowIndex]._height
		
			-- Reposition the scrollbar, if it exists
			if self._scrollBar then
				self._scrollBar:repositionY()
			end
		
			-- Create the row
			self:_createRowAtIndex( index, self._rows[rowIndex] )     
		
		-- calculate the location where the first row will need to slide into (this is useful for the transition animation at the end)
			if (i == 1) then
				if self._rows[rowIndex]._view then
					newRowTop = self._rows[rowIndex].y - self._rows[rowIndex]._height * 0.5
					if isGraphicsV1 then
						newRowTop = self._rows[rowIndex].y 
					end
					self._rows[rowIndex]._view.y = newRowTop
				end
			else -- rows past 1
				if newRowTop and self._rows[rowIndex]._view then   -- fix other rows only if first row has a top
					self._rows[rowIndex]._view.y = self._rows[rowIndex-1]._view.y + self._rows[rowIndex-1]._height
				end
			end		
		
			-- Recalculate the categories if we inserted one
			if self._rows[rowIndex].isCategory then
				self._categories, self._numCategories = self:_gatherCategories()
			end
		
			-- collect the rows into the insertGroup ONLY if the first row had a view, and this one has a view
			if newRowTop and self._rows[rowIndex]._view then
				insertGroup:insert(self._rows[rowIndex]._view)
			end	
		
	end
	
		local totalHeightAboveInsert = 0
		for i = 1, index  -1 do
			totalHeightAboveInsert = totalHeightAboveInsert + self._rows[i]._height
		end


		-- slide down the rows which have a _view 			
		local slideDownGroup = display.newGroup()
		slideDownGroup.anchorChildren = true
		slideDownGroup.anchorX = 0	
		slideDownGroup.anchorY = 0	

		--slideDownGroup.y = self.y + self._rows[index].y + display.contentHeight*0.5  - 1    
		slideDownGroup.y  = self.y + self._origtop + totalHeightAboveInsert 
			--self._rows[i].id = i   --don't change previously assigned id, since it may be a custom value


		-- find the height we have to transition down the rows below the insert
		local slideDownHeight = 0
		for i = index, index + numRows -1 do
			slideDownHeight = slideDownHeight + self._rows[i]._height
		end
		
		-- Update the rowIndex and y pos of all following rows
		for i = index + numRows, table.maxn(self._rows) do
			--self._rows[i].id = i   --don't change previously assigned id, since it may be a custom value
			self._rows[i].index = i
						
			self._rows[i].y = self._rows[i].y + slideDownHeight	
			if self._rows[i]._view ~= nil then
				slideDownGroup:insert(self._rows[i]._view)
			end					
		end
	
		local containerYAdjust = (display.contentHeight - self._height) *0.5 - self._origtop 
	
		local container = display.newContainer( display.contentWidth , self._height )
		container:translate( display.contentWidth*0.5, display.contentHeight*0.5 - containerYAdjust )--+  self._origtop*0.5) 
		container:insert(slideDownGroup)
		slideDownGroup.x = slideDownGroup.x - display.contentWidth*0.5
		slideDownGroup.y = slideDownGroup.y - display.contentHeight*0.5 + containerYAdjust -- - self._origtop * 0.5
		container:insert(insertGroup)
	
		-- if newTop==nil, then the inserted rows are out of the visible region - so no need to animate...
		if newRowTop == nil then
			display.remove(insertGroup)
			insertGroup = nil

			display.remove(slideDownGroup)
			slideDownGroup = nil
			
			display.remove(container)
			container = nil
			
			view:_reloadData()

			-- re-enable enterFrame listener	
			Runtime:addEventListener( "enterFrame", view )	
								
			if options.onComplete and type(options.onComplete) == "function" then
				options.onComplete()
			end
			
			return	
		end
	
		-- depending on the slide direction of the insert, pre-position the newly created rows
		if slideDirection == "left" then
			insertGroup.x = display.contentWidth								
			insertGroup.y = slideDownGroup.y --newRowTop + display.contentHeight *0.5 - 1			
		elseif slideDirection == "right"  then
			insertGroup.x = -display.contentWidth *1.5
			insertGroup.y = slideDownGroup.y --newRowTop + display.contentHeight *0.5 - 1									
		elseif slideDirection == "down"  then
			--insertGroup.y = -insertGroup.contentHeight -- hide just above top
			insertGroup.x = -display.contentWidth * 0.5
--			insertGroup.y = slideDownGroup.y - display.contentHeight *0.5
			insertGroup.y = - display.contentHeight *0.5 - insertGroup.contentHeight  --+ self._origtop*0.5
		elseif slideDirection == "up"  then
			insertGroup.x = -display.contentWidth * 0.5
			insertGroup.y = display.contentHeight * 0.5-- hide just below bottom
		end		
		
		local newInsertRowY = slideDownGroup.y
		
		
		local function slideDownComplete()
				
			local function reloadView()
				
				while slideDownGroup.numChildren > 0 do
					-- update the y pos of all the views in the slideDown group
					slideDownGroup[slideDownGroup.numChildren].y = slideDownGroup[slideDownGroup.numChildren].y  + slideDownHeight
					self:insert(slideDownGroup[slideDownGroup.numChildren])
			end
				display.remove(slideDownGroup)
				slideDownGroup = nil

				-- deconstruct insertGroup and put rows back into tableview where they belong
				while insertGroup.numChildren > 0 do
					self:insert(insertGroup[insertGroup.numChildren])
		end
				display.remove(insertGroup)
				insertGroup = nil

				display.remove(container)
				container = nil

				-- re-enable enterFrame listener	
				Runtime:addEventListener( "enterFrame", view )	
								
				if options.onComplete and type(options.onComplete) == "function" then
					options.onComplete()
				end
				
			end
					
			-- transition the newly created row
			if newRowTop then
				-- Position the row
--				local rowX = 0
				local rowX = -display.contentWidth*0.5
				if isGraphicsV1 then
					rowX = self._width * 0.5
				end

				if slideDirection == "left" or slideDirection == "right" then	
					transition.to(insertGroup, {time=350,  x = rowX , transition=easing.outExpo, onComplete = reloadView})
				elseif slideDirection == "up" or slideDirection =="down"  then

--					transition.to(insertGroup, {time=350,  y = newRowTop + display.contentHeight*0.5 - 1 , transition=easing.outBounce, onComplete = reloadView})
					transition.to(insertGroup, {time=350,  y = newInsertRowY , transition=easing.outBounce, onComplete = reloadView})
				end

			end
			
		end
		if (slideDownHeight > display.contentHeight) then	
			transition.to(slideDownGroup, {time=350, y = slideDownGroup.y + display.contentHeight, transition=easing.inExpo,  onComplete = slideDownComplete})
		else
			transition.to(slideDownGroup, {time=350, y = slideDownGroup.y + slideDownHeight , transition=easing.inExpo,  onComplete = slideDownComplete})
		end							
		
	end


	
	-- Function to delete a row from the tableView
	function view:_deleteRow( rowIndex, options)	
		if type( self._rows[rowIndex] ) ~= "table" then
			print( "WARNING: deleteRow( " .. rowIndex .. " ) - Row does not exist" )
			return
		end
		
		-- Deleting categories isn't currently supported
		if self._rows[rowIndex].isCategory then
			print( "Warning: deleting categories is not supported" )
			return
		end
		
		-- If the view is scrolling, don't allow a row to be deleted
		if mAbs( self._velocity ) > 0 then
			print( "Warning: A row cannot be deleted whilst the tableView is scrolling" , self._velocity)
			
			--return
		end
		
		if (options.transitionTime == nil) then
			options.transitionTime = 500
		end

		
		-- Function to remove the row from display
		local function removeRow()	
			
			-- Loop through the remaining rows, starting at the next row after the deleted one
			for i = rowIndex + 1, table.maxn(self._rows) do
				-- Move up the row's which are within our views visible bounds
				if nil~= self._rows[i] then
					
					self._rows[i].index = i-1

					if nil~= self._rows[i]._view and "table" == type( self._rows[i]._view ) then
						
						if self._rows[i].isCategory then
							if nil ~= self._rows[i-1] then
								--							transition.to( self._rows[i]._view, { y = self._rows[i]._view.y - ( self._rows[rowIndex]._view.contentHeight ) + 1, transition = easing.outQuad } )
								if (nil ~= self._rows[rowIndex]._view) then
									transition.to( self._rows[i]._view, { y = self._rows[i]._view.y - ( self._rows[rowIndex]._view.contentHeight )  , transition = easing.outQuad } )
								end
								self._rows[i].y = self._rows[i].y - ( self._rows[i-1]._height )   -- correct? Or is it    self._rows[i].y - ( self._rows[rowIndex]._height ) 
							end
						else
							--						transition.to( self._rows[i]._view, { y = self._rows[i]._view.y - ( self._rows[rowIndex]._view.contentHeight ) + 1, transition = easing.outQuad } )
							-- Do transition only if the deleted row is within the view
							if (nil ~= self._rows[rowIndex]._view) then
								transition.to( self._rows[i]._view, { y = self._rows[i]._view.y - ( self._rows[rowIndex]._view.contentHeight )   , transition = easing.outQuad } )
							end
							self._rows[i].y = self._rows[i].y - ( self._rows[rowIndex]._height ) 
						end
						
					-- We are now moving up the off screen rows
					else
						if self._rows[i].isCategory then
							if nil ~= self._rows[i-1] then
								self._rows[i].y = self._rows[i].y - ( self._rows[rowIndex]._height ) 
							end
						else
							self._rows[i].y = self._rows[i].y - ( self._rows[rowIndex]._height ) 
						end
				end
				end
			end
						
			-- Remove the row from display
			--display.remove( self._rows[rowIndex]._view )
			if (self._rows[rowIndex]._view ~= nil) then
				cleanNestedDisplayGroups(self._rows[rowIndex]._view) 
				self._rows[rowIndex]._view = nil
			end
							
			-- Remove the row from the rows table
		--	self._rows[rowIndex] = nil  					
			table.remove(self._rows, rowIndex)	
			
			local function deleteTransitionComplete()
				
				print("RELOAD DATA!!!")
				view:_reloadData()
						
				if (options.onComplete ~= nil) then
				options.onComplete()
				end
			end
			
			timer.performWithDelay( options.transitionTime, deleteTransitionComplete, 1 )			
			
			
		end
		
		-- If the row is within the visible view
		if "table" == type( self._rows[rowIndex]._view ) then
						
			-- Transition out & delete the row in question
			-- decrement the table rows variable
			self._numberOfRows =  self._numberOfRows - 1
			-- remove the event listeners on the row before starting the transition
			self._rows[rowIndex]._view:removeEventListener( "touch", _handleRowTouch )
			self._rows[rowIndex]._view:removeEventListener( "tap", _handleRowTap )
			
			-- Re calculate the scrollHeight
			self._scrollHeight = self._scrollHeight - self._rows[rowIndex]._height
			-- only if the scrollbar exists, reposition it
			if self._scrollBar then
				self._scrollBar:repositionY()
			end
			
			-- transition the row			
			
			transition.to( self._rows[rowIndex]._view, { time = options.transitionTime, x = - ( self._rows[rowIndex]._view.contentWidth * 0.5 ), transition = easing.inQuad, onComplete = removeRow } )
						
		-- The row isn't within the visible bounds of our view
		else
			
			-- Re calculate the scrollHeight
			self._scrollHeight = self._scrollHeight - self._rows[rowIndex]._height
			self._scrollBar:repositionY()
		
			-- decrement the table rows variable
			self._numberOfRows =  self._numberOfRows - 1
			removeRow()
		end
		
		-- NOTE: this was the previous location of the scrollHeight calculation. If we resize the scrollheight after the transition.to above, you get a funny motion effect on the tableview. This way, it does not happen.
		
	end


	-- Function to delete rows from the tableView at a given index
	function view:_deleteRowsAtIndex( startRowIndex, endRowIndex, options)			
				
		if (startRowIndex > endRowIndex) then
			print( "ERROR: EndRowIndex must be greater or equal to StartRowIndex" )
			return
		end		
				
		if type( self._rows[startRowIndex] ) ~= "table" then
			print( "ERROR: StartRowIndex: " .. startRowIndex .. " ; Row does not exist" )
			return
		end

		if type( self._rows[endRowIndex] ) ~= "table" then
			print( "ERROR: EndRowIndex: " .. endRowIndex .. " ; Row does not exist" )
			return
		end

		for i = startRowIndex, endRowIndex do
			if self._rows[i].isCategory then
				print( "Warning: deleting categories is not supported; Row "..i.." is a category" )
				return
			end			
		end
			

		--disable enterFrame listener
		Runtime:removeEventListener( "enterFrame", view )	
			

			local deleteCount = endRowIndex - startRowIndex + 1
			local totalDeleteHeight = 0  --  total height of all rows to be deleted
			local totalDeleteNoViewAboveHeight = 0 -- total height of deleted rows with no views above first visible delete row
			local totalHeightAboveDelete = 0 -- height of all rows above the first row to be deleted
			local totalHeightUptoDelete = 0 -- height of all rows up to and including the last row to be deleted
			local hasViews = false

			for i = startRowIndex, endRowIndex do
				totalDeleteHeight = totalDeleteHeight + self._rows[i]._height		
				if type( self._rows[i]._view ) == "table"  then
					hasViews = true
				end	
				
				if hasViews == false then
					totalDeleteNoViewAboveHeight = totalDeleteNoViewAboveHeight + self._rows[i]._height
				end
											
			end			
						
			if startRowIndex > 1 then				
				for i = 1, startRowIndex-1 do
					totalHeightAboveDelete = totalHeightAboveDelete + self._rows[i]._height
				end			
			end
			
			for i = 1, endRowIndex do
				totalHeightUptoDelete = totalHeightUptoDelete + self._rows[i]._height
			end
			
			self._numberOfRows =  self._numberOfRows - deleteCount
			self._scrollHeight = self._scrollHeight - totalDeleteHeight
			if self._scrollBar then
				self._scrollBar:repositionY()
			end
			
			
			-- CONDITION #1
			-- if none of the to-be-deleted rows have a view, then no need to do transition animations				
			if (hasViews == false)  then				
				for i = endRowIndex + 1, table.maxn(self._rows) do
					self._rows[i].index = self._rows[i].index - deleteCount
					self._rows[i].y = self._rows[i].y - totalDeleteHeight					
					if type( self._rows[i]._view ) == "table" then
						self._rows[i]._view.y = self._rows[i]._view.y - totalDeleteHeight
					end					
				end				
				
				for i = startRowIndex, endRowIndex do							
					table.remove(self._rows, startRowIndex)		
				end												
				
				local absTableHeight = 0
				for i = 1, table.maxn(self._rows) do							
					absTableHeight = absTableHeight + self._rows[i]._height	
				end			
													
				-- if table has disappeared above top due to the delete, then reset view to keep the same table view	
				if table.maxn(self._rows) > 0 and self.y +  absTableHeight <  self._rows[table.maxn(self._rows)]._height then					
					self.y = self.y + totalDeleteHeight
					Runtime:addEventListener( "enterFrame", view )	
					
					if options.onComplete and type(options.onComplete) == "function" then
						options.onComplete()
					end
				else -- deletion happened below the view; no need to scroll
					Runtime:addEventListener( "enterFrame", view )					
					if options.onComplete and type(options.onComplete) == "function" then
						options.onComplete()
					end
				end
				
				return	
							
			end
			

			local deleteGroup = display.newGroup()
			deleteGroup.anchorChildren = true
			deleteGroup.anchorX = 0	
			deleteGroup.anchorY = 0		
			for i = startRowIndex, endRowIndex do							
				if type( self._rows[i]._view ) == "table" then 
					self._rows[i]._view:removeEventListener( "touch", _handleRowTouch )
					self._rows[i]._view:removeEventListener( "tap", _handleRowTap )
					
					deleteGroup:insert(self._rows[i]._view)	
				end
			end	
			deleteGroup.y = self.y + self._origtop + totalHeightAboveDelete + totalDeleteNoViewAboveHeight--firstDeleteViewY	-- is this correct?			
				
			local containerYAdjust = (display.contentHeight - self._height) *0.5 - self._origtop 	
			local container = display.newContainer( display.contentWidth , self._height )
			container:translate( display.contentWidth*0.5, display.contentHeight*0.5 - containerYAdjust )--+  self._origtop*0.5) 
			container:insert(deleteGroup)
			deleteGroup.x = deleteGroup.x - display.contentWidth*0.5
			deleteGroup.y = deleteGroup.y - display.contentHeight*0.5 + containerYAdjust -- - self._origtop * 0.5
		
			
			-- CONDITION #2	
			-- If deleting last rows then only slide out deleted rows. there is no need for slide up animation
			if endRowIndex == table.maxn(self._rows)  then
		
					local function reloadViewAfterDeleteLast()
			
						while deleteGroup.numChildren > 0 do
							cleanNestedDisplayGroups(deleteGroup[deleteGroup.numChildren]) 
							deleteGroup[deleteGroup.numChildren] = nil
						end
						display.remove(deleteGroup)
						deleteGroup = nil				
						
						for i = startRowIndex, endRowIndex do							
							table.remove(self._rows, startRowIndex)		
						end	

						display.remove(container)
						container = nil
						
						-- re-enable enterFrame listener	
						Runtime:addEventListener( "enterFrame", view )	
						
						local absTableHeight = 0
						for i = 1, table.maxn(self._rows) do							
							absTableHeight = absTableHeight + self._rows[i]._height	
						end			
						-- if table has disappeared above top due to the delete, then scroll down a row				
						if table.maxn(self._rows) > 0 and self.y + self._origtop + absTableHeight < self._origtop  + self._rows[table.maxn(self._rows)]._height then
							
							local function scrollToComplete()
								if options.onComplete and type(options.onComplete) == "function" then
									options.onComplete()
								end						
							end
							
							view:_scrollToY( {y =  -absTableHeight +  self._rows[table.maxn(self._rows)]._height, time = 550, onComplete = scrollToComplete} )
		
						else
							if options.onComplete and type(options.onComplete) == "function" then
								options.onComplete()
							end
						end
						
						return	
									
					end
			
					transition.to( deleteGroup, { time=500, x = deleteGroup.x - display.contentWidth  , transition = easing.outQuad, onComplete= reloadViewAfterDeleteLast } )							
					return
			
			end

			local slideUpGroup = display.newGroup()
			slideUpGroup.anchorChildren = true
			slideUpGroup.anchorX = 0	
			slideUpGroup.anchorY = 0	
			slideUpGroup.y  = self.y + self._origtop + totalHeightUptoDelete 
			
			local containerYAdjust = (display.contentHeight - self._height) *0.5 - self._origtop 	
			local container = display.newContainer( display.contentWidth , self._height )
			container:translate( display.contentWidth*0.5, display.contentHeight*0.5 - containerYAdjust )--+  self._origtop*0.5) 
			container:insert(slideUpGroup)
			slideUpGroup.x = slideUpGroup.x - display.contentWidth*0.5
			slideUpGroup.y = slideUpGroup.y - display.contentHeight*0.5 + containerYAdjust -- - self._origtop * 0.5
	
	
			local slideUpGroupHeight = 0
			-- Loop through the remaining rows, starting at the next row after the deleted one
			for i = endRowIndex + 1, table.maxn(self._rows) do
				local currentRow = self._rows[i]
			
				if view:_isRowWithinBounds(currentRow, 0, totalDeleteHeight) and type( currentRow._view ) ~= "table" and slideUpGroupHeight < self._height then
						self:_createRowAtIndex( i, currentRow, 0, totalDeleteHeight )
				end

				currentRow.index = currentRow.index-deleteCount
				currentRow.y = currentRow.y - totalDeleteHeight	

				if currentRow._view ~= nil then
					slideUpGroup:insert(currentRow._view)
					slideUpGroupHeight = slideUpGroupHeight + currentRow._height
				end						
			end
									
			local function slideOutComplete()
				
				local slideUpClamped = false
		
					local function processAfterSlideUp()
			
							-- Remove the row completely
							while deleteGroup.numChildren > 0 do
									cleanNestedDisplayGroups(deleteGroup[deleteGroup.numChildren]) 
									deleteGroup[deleteGroup.numChildren] = nil
							end
							display.remove(deleteGroup)
							deleteGroup = nil				
														
							for i = startRowIndex, endRowIndex do							
								table.remove(self._rows, startRowIndex)		
							end	
											
							while slideUpGroup.numChildren > 0 do
								-- update the y pos of all the views in the slideUpGroup  NOT NEEDED SINCE THE VIEWS WILL BE RECONSTRUCTED DURING LIFECYCLE RENDERING
								slideUpGroup[slideUpGroup.numChildren].y = slideUpGroup[slideUpGroup.numChildren].y  - totalDeleteHeight
								self:insert(slideUpGroup[slideUpGroup.numChildren])
							end
							display.remove(slideUpGroup)
							slideUpGroup = nil				
			
							display.remove(container)
							container = nil
		
							-- re-enable enterFrame listener	
							Runtime:addEventListener( "enterFrame", view )		
		
							local absTableHeight = 0
							for i = 1, table.maxn(self._rows) do							
								absTableHeight = absTableHeight + self._rows[i]._height	
							end			
							-- if table has disappeared above top due to the delete, then scroll down a row				
							if not slideUpClamped and table.maxn(self._rows) > 0 and self.y +  absTableHeight <  self._rows[table.maxn(self._rows)]._height then
								-- This block may never execute since we use clamping...?
								--print("TABLE DISAPPEARED!")
								local function scrollToComplete()
									if options.onComplete and type(options.onComplete) == "function" then
										options.onComplete()
									end			
								end
								
								local scrollHeight = 0
								for i = table.maxn(self._rows), 1, -1 do
									if  scrollHeight + self._rows[i]._height > self._height then
										break
									end
									scrollHeight = scrollHeight + self._rows[i]._height
										
								end
								view:_scrollToY( {y =  -absTableHeight +  scrollHeight, time = 550, onComplete = scrollToComplete} )
			
							elseif slideUpClamped then
								self.y = -totalHeightAboveDelete -- resets view to align at the bottom row above deletion
								if options.onComplete and type(options.onComplete) == "function" then
									options.onComplete()
								end						
															
							else
								if options.onComplete and type(options.onComplete) == "function" then
									options.onComplete()
								end
							end
					
					end
		
		
				local slideUpHeight = totalDeleteHeight
				if (totalDeleteHeight > slideUpGroup.y + display.contentHeight*0.5 - containerYAdjust - self._origtop) then  -- slide up goes past top, so clamp
					-- Note: slideUpGroup.y + display.contentHeight*0.5 - containerYAdjust - self._origtop is the y pos of the top of slideUpGroup from the top of the physical screen
					--slideUpClampAdjustment = totalDeleteHeight - slideUpGroup.y + display.contentHeight*0.5 - containerYAdjust - self._origtop
					slideUpHeight = slideUpGroup.y + display.contentHeight*0.5 - containerYAdjust - self._origtop
					slideUpClamped = true				
				end
				
				transition.to( slideUpGroup, { time=500, y = slideUpGroup.y - slideUpHeight  , transition = easing.outQuad, onComplete= processAfterSlideUp } )			
									
			end
			
			transition.to( deleteGroup, { time=500, x = deleteGroup.x - display.contentWidth  , transition = easing.outQuad, onComplete= slideOutComplete } )			
			
				
	end
	
	
	
	
	-- Function to deleta all rows from the tableView
	function view:_deleteAllRows()
		local _tableView = self.parent
		self._numberOfRows = 0
		
		-- Loop through all rows and delete each one
		for i = 1, table.maxn(self._rows) do
			if nil ~= self._rows[i] then
				if nil ~= self._rows[i]._view and "table" == type( self._rows[i]._view ) then
					cleanNestedDisplayGroups(self._rows[i]._view) 
					self._rows[i]._view = nil
				end
			end
		end
		
		-- Remove & reset the row's table
		self._rows = nil
		self._rows = {}
				
		-- Delete any stuck categories
		if self._currentCategory then
			display.remove( self._currentCategory )
			self._currentCategory = nil
			self._currentCategoryIndex = nil
		end
	
		-- Nil out the categories table
		self._categories = nil
		
		-- Remove the scrollbar
		if self._scrollBar then
			display.remove( self._scrollBar )
			self._scrollBar = nil
		end
		
		-- Reset the view's y position
		self.y = _tableView.y - self._top + self._topPadding
		
		-- Reset the scrollHeight
		self._scrollHeight = 0
	end
	
	-- Function to scroll to a specific row
	function view:_scrollToIndex( ... )
		local arg = { ... }
		local rowIndex = nil
		local time = nil
		local executeOnComplete = nil
		
		if "number" == type( arg[1] ) then
			rowIndex = arg[1]
		end
		
		if "number" == type( arg[2] ) then
			time = arg[2]
		elseif "function" == type( arg[2] ) then
			executeOnComplete = arg[2]
		end
				
		if "function" == type( arg[3] ) then
			executeOnComplete = arg[3]
		elseif "function" == type( arg[4] ) then
			executeOnComplete = arg[4]
		end
		
		local scrollTime = time or 400
		
		-- this makes no sense
		if self._lastRowIndex == rowIndex then
			--return
		end
				
		-- The new position to scroll to
		local newPosition = 0

		-- Set the new position to scroll to. Accounting for the 0.5 anchor of the widget
		newPosition = -self._rows[rowIndex].y + ( self._rows[rowIndex]._height * 0.5 )

		if not isGraphicsV1 then
			newPosition = newPosition - self.parent.contentHeight * 0.5
		end
		
		-- The calculation needs altering for pickerWheels
		if self._isUsedInPickerWheel then
			-- TODO: this is just because we have a single theme for all the pickers, we'll have to add a real solution here.
			local jumpY = - 26 - self._rows[rowIndex].y + ( self._rows[rowIndex]._height * 0.5 )
			if isGraphicsV1 then
				jumpY =  - self._rows[rowIndex]._height * 0.5 - self._rows[rowIndex].y + ( self._rows[rowIndex]._height * 0.5 )
			end
			newPosition = jumpY
		end
		
		--Check if a category is displayed, so we adjust the position with the height of the category
		if nil ~= self._currentCategory and nil ~= self._currentCategory.contentHeight and not self._isUsedInPickerWheel then
			newPosition = newPosition + self._currentCategory.contentHeight
		end
			
		-- Transition the view to the row index	
		transition.to( self, { y = newPosition, time = scrollTime, transition = easing.outQuad, onComplete = executeOnComplete } )
		
		-- Update the last row index
		self._lastRowIndex = rowIndex
	end
	
	-- Function to scroll to a specific y position
	function view:_scrollToY( options )
		local newY = options.y
		local transitionTime = options.time or 400
		local onTransitionComplete = options.onComplete
		
		-- Stop updating Runtime & tracking velocity
		self._updateRuntime = false
		self._trackVelocity = false
		-- Reset velocity back to 0
		self._velocity = 0		
	
		transition.to( self, { y = newY, time = transitionTime, transition = easing.inOutQuad, onComplete = onTransitionComplete } )
	end
	
	-- Function to re-render the rows
	function view:_reloadData()
		
		-- calculate the view limits
		local upperLimit = self._background.y - ( self._background.contentHeight * 0.5 )
		local lowerLimit = self._background.y + ( self._background.contentHeight * 0.5 )
		for i, row in pairs( self._rows ) do
--			local isRowWithinBounds = ( row.y + self.y ) + row._height > upperLimit and ( row.y + self.y ) - row._height * 2 < lowerLimit
			local isRowWithinBounds = ( row.y + self.y ) + row._height * 2 > upperLimit and ( row.y + self.y ) - row._height * 2 < lowerLimit
			-- if the row is visible, re-render it
			if isRowWithinBounds then
				self:_createRow( row, true )
			end
		end
	end
	
	-- isLocked variable setter function
	function view:_setIsLocked( lockedState )
		if type( lockedState ) ~= "boolean" then return end
		self._isVerticalScrollingDisabled = lockedState
		self._isLocked = lockedState
	end
	
	
	-- Finalize function for the tableView
	function tableView:_finalize()
		Runtime:removeEventListener( "enterFrame", self._view )
		Runtime:removeEventListener( "system", _handleSuspendResume )
		
		display.remove( self._view._categoryGroup )
	
		self._view._categoryGroup = nil
	
		-- Remove scrollBar if it exists
		if self._view._scrollBar then
			display.remove( self._view._scrollBar )
			self._view._scrollBar = nil
		end
	end
			
	return tableView
end


-- Function to create a new tableView object ( widget.newtableView )
function M.new( options, theme )	
	local customOptions = options or {}
	local themeOptions = theme or {}
	
	-- Create a local reference to our options table
	local opt = M._options
	
	-------------------------------------------------------
	-- Properties
	-------------------------------------------------------

	-- Positioning & properties
	opt.left = customOptions.left or 0
	opt.top = customOptions.top or 0
	opt.x = customOptions.x or nil
	opt.y = customOptions.y or nil
	if customOptions.x and customOptions.y then
		opt.left = 0
		opt.top = 0
	end	
	opt.width = customOptions.width or display.contentWidth
	opt.height = customOptions.height or display.contentHeight
	opt.id = customOptions.id
	opt.baseDir = customOptions.baseDir or system.ResourceDirectory
	opt.maskFile = customOptions.maskFile
	opt.listener = customOptions.listener
		
	-- Properties
	opt.shouldHideBackground = customOptions.hideBackground or false
	opt.backgroundColor = customOptions.backgroundColor or themeOptions.colours.whiteColor
	opt.topPadding = customOptions.topPadding or 0
	opt.bottomPadding = customOptions.bottomPadding or 0
	opt.leftPadding = customOptions.leftPadding or 0
	opt.rightPadding = customOptions.rightPadding or 0
	opt.isHorizontalScrollingDisabled = true -- We explicitly disable this as tableViews (aka listViews) only scroll vertically
	opt.isVerticalScrollingDisabled = customOptions.isLocked or false
	opt.friction = customOptions.friction
	opt.maxVelocity = customOptions.maxVelocity
	opt.noLines = customOptions.noLines or false
	opt.hideScrollBar = customOptions.hideScrollBar or false
	opt.isLocked = customOptions.isLocked or false
	opt.rowWidth = opt.width
	opt.rowHeight = customOptions.rowHeight or 40
	opt.onRowRender = customOptions.onRowRender
	opt.onRowUpdate = customOptions.onRowUpdate
	opt.onRowTouch = customOptions.onRowTouch
	opt.scrollStopThreshold = customOptions.scrollStopThreshold or 250
	opt.autoHideScrollBar = true
	if nil ~= customOptions.autoHideScrollBar and customOptions.autoHideScrollBar == false then
		opt.autoHideScrollBar = false
	end
	
	opt.isBounceEnabled = true
	if nil ~= customOptions.isBounceEnabled and customOptions.isBounceEnabled == false then 
		opt.isBounceEnabled = false
	end
	opt.rowTouchDelay = customOptions.rowTouchDelay or 110
	
	-- ScrollBar options
	if customOptions.scrollBarOptions then
		opt.scrollBarOptions =
		{
			sheet = customOptions.scrollBarOptions.sheet,
			topFrame = customOptions.scrollBarOptions.topFrame,
			middleFrame = customOptions.scrollBarOptions.middleFrame,
			bottomFrame = customOptions.scrollBarOptions.bottomFrame,
			frameWidth = customOptions.scrollBarOptions.frameWidth,
			frameHeight = customOptions.scrollBarOptions.frameHeight
		}
	else
		opt.scrollBarOptions = {}
	end
	
	-- set the theme params
	opt.themeParams = themeOptions
	

	-------------------------------------------------------
	-- Create the tableView
	-------------------------------------------------------
		
	-- Create the tableView object
	local tableView = _widget._newContainer
	{
		left = opt.left,
		top = opt.top,
		id = opt.id or "widget_tableView",
		baseDir = opt.baseDir,
		widgetType = "tableView"
	}

	-- Create the tableView
	createTableView( tableView, opt )
	
	tableView.width = opt.width
	tableView.height = opt.height
	
	local x, y = _widget._calculatePosition( tableView, opt )
	tableView.x, tableView.y = x, y
	
	return tableView
end

return M