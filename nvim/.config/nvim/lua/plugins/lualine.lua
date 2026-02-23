return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- find and remove the updates component from lualine_x
      local section = opts.sections.lualine_x
      for i = #section, 1, -1 do
        local comp = section[i]
        -- compare by function reference or by checking if comp uses lazy.status.updates
        if type(comp) == "table" and comp[1] == require("lazy.status").updates then
          table.remove(section, i)
        end
      end
    end,
  },
}
