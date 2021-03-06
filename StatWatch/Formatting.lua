-- ****************************************************************************
-- ****************************************************************************
--
-- Number formatting
--
-- ****************************************************************************
-- ****************************************************************************

function FormatNumber(number, decimals)
    if number < 1000 then
        return string.format("%." .. tostring(decimals or 0) .. "f", number)
    elseif number < 600000 then
        return string.format("%d,%03d", (number+0.5)/1000, (number+0.5)%1000)
    elseif number < 1000000 then
        return string.format("%.1fk", (number+0.5)/1000)
    elseif number < 1500000 then
        return string.format("%d,%03.1fk", (number+0.5)/1000000, ((number+0.5)%1000000)/1000)
    else
        return string.format("%.2fM", number/1e6)
    end
end

function FormatPercent(value)
    if value == nil then return nil end
    return string.format("%.1f %%", value)
end

function FormatPercentDiff(value) return string.format("%+.1f %%", value) end
function FormatELM(value) return string.format("x %3.1f", value) end

