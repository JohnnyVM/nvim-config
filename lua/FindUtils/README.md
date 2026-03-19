# FindUtils Module

This is a Neovim Lua module that provides enhanced search functionality.

## Features

- **FindAll**: Search for a pattern in all open buffers AND files in the current directory
- **FindBuf**: Search for a pattern only in open buffers
- Automatic fallback to ripgrep (`rg`) when available for better performance
- Binary file detection to avoid searching non-text files
- Progress notifications for large directory searches
- Proper handling of Neovim's quickfix list

## Usage

### Commands

- `:FindAll <pattern>` - Search for pattern in all open buffers and files
- `:FindBuf <pattern>` - Search for pattern only in open buffers

### Manual Function Calls

```lua
local FindUtils = require("lua.FindUtils")

-- Search in all files
FindUtils.find_all("your_search_pattern")

-- Search in open buffers only
FindUtils.find_buf("your_search_pattern")
```

## Implementation Details

The module implements smart search logic:
1. First searches in open buffers using built-in Neovim search
2. If ripgrep is available, uses it for faster directory search
3. Falls back to Neovim's built-in search for systems without ripgrep
4. Filters out binary files and hidden directories
5. Provides progress updates for large searches