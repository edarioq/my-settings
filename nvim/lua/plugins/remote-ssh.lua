return {
  "amitds1997/remote-nvim.nvim",
  version = "*", -- Pin to GitHub releases
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-telescope/telescope.nvim", -- Optional: For picking SSH hosts visually
  },
  config = function()
    require("remote-nvim").setup({
      -- Devpod, Docker, or SSH config
      ssh_config = {
        ssh_binary = "ssh",
      },
    })
  end,
}
