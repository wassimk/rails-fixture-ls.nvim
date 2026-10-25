# README demo for rails-fixture-ls.nvim
#
# Render from the repo root:
#   vhs demo/rails-fixture-ls.tape
#
# Runs in demo/sample, a tiny Rails-style project with test fixtures. The test file is edited
# in the buffer but never saved.

Output demo.gif

Require bash
Require git
Require nvim

Set Shell "bash"
Set FontFamily "MonoLisaCode, JetBrainsMono Nerd Font"
Set FontSize 15
Set Width 1000
Set Height 600
Set Padding 16
Set Theme "OneHalfDark"
Set TypingSpeed 70ms
Set CursorBlink false

# Setup: open the test file in nvim with the minimal config
Hide
Type "cd demo/sample && nvim -u ../init.lua test/models/post_test.rb"
Enter
Wait+Screen@60s /class PostTest/
Sleep 1.5s
Show

Sleep 800ms

# Completion: fixture names with a YAML preview
Type "7G"
Sleep 400ms
Type "o"
Type "user = users(:"
Wait+Screen /:charlie/
Sleep 2s
Type "ch"
Sleep 1.5s
Enter
Type ")"
Escape
Sleep 800ms

# Hover a fixture name: its YAML attributes
Type "F:l"
Sleep 400ms
Type "K"
Wait+Screen /Charlie Lee/
Sleep 3s

# Hover a fixture type: all its names and the file path
Type "^ww"
Sleep 400ms
Type "K"
Wait+Screen /users\.yml/
Sleep 3s

# Go to definition of the fixture name, then jump back
Type "f:l"
Sleep 400ms
Type "gd"
Wait+Screen /charlie:/
Sleep 3s
Ctrl+O
Wait+Screen /class PostTest/
Sleep 1s

# Go to definition of the fixture type: the YAML file
Type "^ww"
Sleep 400ms
Type "gd"
Wait+Screen /users\.yml/

# Hold on the result before looping
Sleep 3s
