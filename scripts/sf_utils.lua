sf_util = {}

function sf_util.checkNextTable(table)
    if table and next(table) then
        return true
    end
    return false
end

function sf_util.invert(int, bool)
    if bool then
        return int * -1
    end
    return int
    -- body
end
