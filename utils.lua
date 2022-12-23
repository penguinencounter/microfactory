local exports = {}

function exports.match_pos(val1, val2)
    local x1 = val1.x or val1[1]
    local y1 = val1.y or val1[2]
    local x2 = val2.x or val2[1]
    local y2 = val2.y or val2[2]
    return x1 == x2 and y1 == y2
end

function exports.dump_table(table, indent)
    if type(table) ~= "table" then
        return tostring(table)
    end
    local indent = indent or 0
    local str = ""
    for k, v in pairs(table) do
        if type(v) == "table" then
            str = str .. string.rep(" ", indent) .. k .. " = {\n"
            str = str .. exports.dump_table(v, indent + 4)
            str = str .. string.rep(" ", indent) .. "}\n"
        else
            str = str .. string.rep(" ", indent) .. k .. " = " .. tostring(v) .. "\n"
        end
    end
    return str
end

function r(table)
    game.print(exports.dump_table(table))
end

function exports.round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function exports.format_digits(num, decimalPlaces)
    -- ensure there are always decimalPlaces digits after the decimal point, even if they are 0
    local str = tostring(num)
    local decimal = string.find(str, "%.")
    if decimal then
        local digits = string.len(str) - decimal
        if digits < decimalPlaces then
            str = str .. string.rep("0", decimalPlaces - digits)
        end
    else
        str = str .. "." .. string.rep("0", decimalPlaces)
    end
    return str
end

exports['pdump'] = r

return exports
