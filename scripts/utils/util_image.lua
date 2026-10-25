image = {}

function image.progress(curr, max, rect, orientation)
    if orientation == "vertical" then
        return string.format("?crop=%s;%s;%s;%s", rect[1], rect[2], rect[3], rect[4] * (curr / max))
    else
        return string.format("?crop=%s;%s;%s;%s", rect[1], rect[2], rect[3] * (curr / max), rect[4])
    end
end

function image.replaceColor(oldColor, newColor)
    local arr = {}
    local palette = ""
    for i = 1, #oldColor do
        table.insert(arr, string.format("%s=%s=%s;", palette, oldColor[i], newColor[i]))
    end
    return "?replace;" .. table.concat(arr)
end

function image.multiply(string, bool)
    if bool then
        string = string * 100
        if string < 10 then
            string = 10
        end
    end
    return "?multiply=FFFFFF" .. string
end
