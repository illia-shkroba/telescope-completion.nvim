local M = {}

M.common_prefix = function(strings)
  local column_uniques = function(i)
    local result = {}
    for _, x in pairs(strings) do
      local key = x:sub(i, i)
      result[key] = true
    end
    return vim.tbl_keys(result)
  end

  local result = ""
  local i = 1
  while true do
    local uniques = column_uniques(i)
    if #uniques == 1 and #uniques[1] > 0 then
      result = result .. uniques[1]
    else
      return result
    end
    i = i + 1
  end
end

M.ends_with_prefix_of = function(str, prefix)
  assert(
    #str <= #prefix,
    "length of string that ends with prefix (left) should be "
      .. "less than or equal to length of string containing prefix (right)"
  )
  local sub_str = str
  local offset = 0
  while true do
    local begin, _ = sub_str:find(prefix:sub(1, 1), 1, true)
    if begin == nil then
      return nil
    end

    local suffix = sub_str:sub(begin)
    if suffix == prefix:sub(1, #suffix) then
      return begin + offset
    else
      sub_str = sub_str:sub(begin + 1)
      offset = offset + begin
    end
  end
end

return M
