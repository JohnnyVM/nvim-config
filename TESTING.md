# Testing FindUtils Manually

Since FindUtils is a Neovim plugin that integrates with Neovim's APIs, it must be tested within Neovim's environment. Here's how to manually verify it works:

## Manual Testing Steps

1. **Start Neovim**:
   ```bash
   nvim
   ```

2. **Verify Commands Exist**:
   In Neovim command mode (`:`), type:
   ```
   :FindAll
   :FindBuf
   ```
   If the commands are registered properly, you should see no errors.

3. **Test Functionality**:
   - Open some files in Neovim
   - Use `:FindAll <pattern>` to search in all files and buffers
   - Use `:FindBuf <pattern>` to search only in open buffers

4. **Check Module Loading**:
   In Neovim, run:
   ```
   :lua require('lua.FindUtils')
   ```
   This should execute without errors.

## Expected Behavior

- `:FindAll <pattern>` - Should search for the pattern in all open buffers and files
- `:FindBuf <pattern>` - Should search only in currently open buffers
- Both commands should open the quickfix window with results
- Should gracefully handle missing ripgrep (falls back to built-in search)
- Should filter out binary files and hidden directories

## Verification

You can verify the module works by checking:
- The quickfix window opens after running the commands
- Results are properly displayed
- No error messages appear
- The search works in both modes (buffers only and all files)

The functionality is automatically loaded when Neovim starts, as configured in init.lua.