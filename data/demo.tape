# VHS documentation
#
# Output:
#   Output <path>.gif               Create a GIF output at the given <path>
#   Output <path>.mp4               Create an MP4 output at the given <path>
#   Output <path>.webm              Create a WebM output at the given <path>
#
# Require:
#   Require <string>                Ensure a program is on the $PATH to proceed
#
# Settings:
#   Set FontSize <number>           Set the font size of the terminal
#   Set FontFamily <string>         Set the font family of the terminal
#   Set Height <number>             Set the height of the terminal
#   Set Width <number>              Set the width of the terminal
#   Set LetterSpacing <float>       Set the font letter spacing (tracking)
#   Set LineHeight <float>          Set the font line height
#   Set LoopOffset <float>%         Set the starting frame offset for the GIF loop
#   Set Theme <json|string>         Set the theme of the terminal
#   Set Padding <number>            Set the padding of the terminal
#   Set Framerate <number>          Set the framerate of the recording
#   Set PlaybackSpeed <float>       Set the playback speed of the recording
#   Set MarginFill <file|#000000>   Set the file or color the margin will be filled with.
#   Set Margin <number>             Set the size of the margin. Has no effect if MarginFill isn't set.
#   Set BorderRadius <number>       Set terminal border radius, in pixels.
#   Set WindowBar <string>          Set window bar type. (one of: Rings, RingsRight, Colorful, ColorfulRight)
#   Set WindowBarSize <number>      Set window bar size, in pixels. Default is 40.
#   Set TypingSpeed <time>          Set the typing speed of the terminal. Default is 50ms.
#
# Sleep:
#   Sleep <time>                    Sleep for a set amount of <time> in seconds
#
# Type:
#   Type[@<time>] "<characters>"    Type <characters> into the terminal with a
#                                   <time> delay between each character
#
# Keys:
#   Escape[@<time>] [number]        Press the Escape key
#   Backspace[@<time>] [number]     Press the Backspace key
#   Delete[@<time>] [number]        Press the Delete key
#   Insert[@<time>] [number]        Press the Insert key
#   Down[@<time>] [number]          Press the Down key
#   Enter[@<time>] [number]         Press the Enter key
#   Space[@<time>] [number]         Press the Space key
#   Tab[@<time>] [number]           Press the Tab key
#   Left[@<time>] [number]          Press the Left Arrow key
#   Right[@<time>] [number]         Press the Right Arrow key
#   Up[@<time>] [number]            Press the Up Arrow key
#   Down[@<time>] [number]          Press the Down Arrow key
#   PageUp[@<time>] [number]        Press the Page Up key
#   PageDown[@<time>] [number]      Press the Page Down key
#   Ctrl+<key>                      Press the Control key + <key> (e.g. Ctrl+C)
#
# Display:
#   Hide                            Hide the subsequent commands from the output
#   Show                            Show the subsequent commands in the output

Output ../img/demo.gif

Set TypingSpeed 200ms
Set FontSize 16
Set Width 1000
Set Height 700
Set Shell "zsh"

Type "vi fib.py" Sleep 500ms Enter
Type "i" Sleep 1
Type "cla" Sleep 1 Tab Sleep 1 Space
Type "Fibonacci" Sleep 500ms Tab
Sleep 1 Tab Sleep 1
Type '"' Sleep 1 Tab Sleep 1 Space
Type "F" Sleep 1 Tab Sleep 1 Space
Type "series" Sleep 1 Escape
Type "odefs" Sleep 1 Tab Sleep 1 Space
Type "get" Sleep 1 Tab
Type "n" Sleep 1 Tab
Type "n1, n2, n3 = 0, 1, 1" Sleep 1 Enter
Type "for" Sleep 1 Tab Sleep 1 Space
Type "_" Sleep 1 Tab
Type "range(n)" Sleep 1 Tab
Type "n3 = n1 + n2" Enter
Type "n1, n2 = n2, n3" Enter
Backspace
Type "retu" Sleep 1 Tab Sleep 1 Space
Type "n3" Sleep 1 Enter 2
Type "# Wr" Sleep 1 Tab Space
Type "some tests." Enter
Type "# I'll use an abbr" Sleep 1 Tab Backspace 2 Space
Type "to insert boilerplate code." Sleep 1 Escape
Type "?get" Sleep 1 Enter
Type "o'''" Sleep 2 Tab Sleep 1 Space
Type "1" Sleep 1 Escape
Type "o1" Sleep 1 Escape Up
Type "2yy" Sleep 1 Down
Type "p" Sleep 1 Down
Type "p" Sleep 3
Type "f1r8" Sleep 2 Down
Type "s34" Sleep 1 Escape
Type "?1" Sleep 1 Enter
Type "r2" Sleep 1
Type "nr2" Sleep 1
Type ":w | new | r !python3 #" Sleep 2 Enter
Sleep 2
Type ":Tests passed!" Sleep 2
Ctrl+u
Type ":qa" Enter
