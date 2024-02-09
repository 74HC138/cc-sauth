local qrdisp = {}

function qrdisp.display(data, t)
    t = t or term
    t.clear()
    t.setCursorPos(1,1)
    local height = #data
    local width = #data[1]
    for y = 1, height, 2 do
        for x = 1, width do
            if (data[y] == nil) then
                t.setTextColor(colors.black)
            else
                if (data[y][x] > 0) then
                    t.setTextColor(colors.black)
                else
                    t.setTextColor(colors.white)
                end
            end
            if (data[y+1] == nil) then
                t.setBackgroundColor(colors.black)
            else
                if (data[y+1][x] > 0) then
                    t.setBackgroundColor(colors.black)
                else
                    t.setBackgroundColor(colors.white)
                end
            end
            t.write(string.char(131))
        end
        local x, y =  t.getCursorPos()
        t.setCursorPos(1, y + 1)
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
end

return qrdisp