# bang.vim

A [Neovim](https://neovim.io) plugin that runs an operation inside of a dedicated buffer.

## Installation

Install using Neovim's built-in package support:
```
mkdir -p ~/.local/share/nvim/site/pack/maroon/start/
cd ~/.local/share/nvim/site/pack/maroon/start/
git clone https://github.com/maroon/bang.vim
```

Or via other plugin managers, such as [vim-plug](https://github.com/junegunn/vim-plug):
```
Plug 'maroon/bang.vim'
```

## Usage

```
:Bang echo "Hello, world."
```

## License

Copyright (c) Ryan Maroon. Distributed under the terms of the MIT license.
