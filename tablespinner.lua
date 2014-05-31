--
-- created with TexturePacker (http://www.codeandweb.com/texturepacker)
--
-- $TexturePacker:SmartUpdate:742cac88299f980feef797378a4e57b2:5554302e36bf8ffa49822788a8187bb8:c8f6ec06e9d943b575ca92ea5393653b$
--
-- local sheetInfo = require("mysheet")
-- local myImageSheet = graphics.newImageSheet( "mysheet.png", sheetInfo:getSheet() )
-- local sprite = display.newSprite( myImageSheet , {frames={sheetInfo:getFrameIndex("sprite")}} )
--

local SheetInfo = {}

SheetInfo.sheet =
{
    frames = {
    
        {
            -- prog1
            x=2,
            y=37,
            width=32,
            height=33,

        },
        {
            -- prog2
            x=36,
            y=70,
            width=33,
            height=32,

        },
        {
            -- prog3
            x=71,
            y=36,
            width=33,
            height=32,

        },
        {
            -- prog4
            x=36,
            y=36,
            width=33,
            height=32,

        },
        {
            -- prog5
            x=2,
            y=2,
            width=32,
            height=33,

        },
        {
            -- prog6
            x=71,
            y=2,
            width=33,
            height=32,

        },
        {
            -- prog7
            x=36,
            y=2,
            width=33,
            height=32,

        },
        {
            -- prog8
            x=71,
            y=70,
            width=32,
            height=32,

        },
    },
    
    sheetContentWidth = 106,
    sheetContentHeight = 104
}

SheetInfo.frameIndex =
{

    ["prog1"] = 1,
    ["prog2"] = 2,
    ["prog3"] = 3,
    ["prog4"] = 4,
    ["prog5"] = 5,
    ["prog6"] = 6,
    ["prog7"] = 7,
    ["prog8"] = 8,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
