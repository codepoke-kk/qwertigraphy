### How to Qwertigraph!

Index: 
[Why Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/HowQwertigraph.md)
[How to Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/WhyQwertigraph.md)
[Broken Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/FixQwertigraph.md)

#### Step: Download AutoHotkey 
https://www.autohotkey.com/download/

#### Step: Install AutoHotkey 
https://www.autohotkey.com/docs/AutoHotkey.htm

AutoHotkey will not do anything when you install it. After installation, it awaits your command to run a script. 

#### Step: Download Qwertigraphy
If you are familiar with the ideas and uses of GitHub, you can go to the repository and clone, pull, or download at will. If all that was Greek to you, then download a zip file of the repository here. Unzip it anywhere you'd like on your computer. I keep mine in a qwertigraphy folder in "My Documents."
https://github.com/codepoke-kk/qwertigraphy/archive/master.zip

A low-quality video walk-through here: [Qwertigraphy Quick Start](https://www.youtube.com/watch?v=z3lnBqlmgmE&feature=youtu.be)

#### Step: Start the Qwertigraph
Go to the /release folder, and double click Qwertigraph.ahk. You should see The Coach appear on the right side of your screen. Move it around as you wish, but it will hover on top until you minimize it. This is its function. 

#### Step: Use the Qwertigraph
Open a simple text editor, a new email, or anything else into which you might wish to type some text. Type "It's time to start". If all has gone well, The Coach should show:
0002: time = tm (tm) [2]
0001: start = stat (stAt) [1]
0001: it = t (t) [1]

Now type "T's tm to stat"

The Coach should now show you've saved 4 characters in typing and have attained a learning level of 1.00. 

##### Tips:
- No word will expand until you stroke an "end character". You have to hit some punctation key to let the Qwertigraph know you're done and ready to move on. 
- Control-Backspace is your friend. If you meant some other word than the one the Qwertigraph typed, Control-Backspace will delete the entire word and let you start over again. (It's much lazier to hit Control-Backspace once than to hit Backspace a does times.)
- Control-j will Suspend the Qwertigraph if you need to type without its help. Control-j again will reactivate it. 
- Control-{ most punctuation marks } will cause the Qwertigraph to ignore whatever word you just typed.
- If you type out a word for which there's a "big win" lazy form, a pop-up tip will give you a hint to that effect.  

#### Step: Use The Coach
##### From the top down:
The Save log and Clear log buttons allow you to output a text file into the Qwertigraph's folder with a list of every word you could have typed lazily.
The squiggle in the top right is the word "coach" written in Gregg Shorthand.

##### The summary at the top means:
- Typed: The total number of the characters you've typed that had meaning to The Coach. Words The Coach does not understand will not be included in this total, so don't expect The Coach to be able to tell you how many Words Per Minute you're typing. You'll need to analyze that the old fashioned way. 
- Saved: The total number of characters the Qwertigraph typed for you upon recognizing a lazy form of a word.
- Missed: The total number of characters you could have saved, had you used a lazy form instead of typing one or more words out the hard way. 
- Efficiency: "Typed" divided by "Saved", which is an indication of how powerful is your laziness. Oddly, as you become a better Qwertigrapher, this number may actually go down, since you'll be able to add fewer and fewer "big win" words and begin adding more "daily use" words with smaller and smaller gains.
- Learning: "Saved" divided by "Missed". This number can be driven higher and higher week after week. As you use more and more lazy forms and miss fewer opportunities to save yourself strokes, this number will climb.

##### The numbered lines:
These are a list of hints with a score. The first 4-digit number is the score you could have saved overall had you been lazy every time you used the word. The remainder of the line is the hint for that word. The first element of the hint is the word itself. The first element after the = sign is the lazy form of the word. Type the lazy form and the word will be typed for you. Within the parentheses is the "formal form" of the word. When you begin to write in Gregg Shorthand, you will write the formal form, not the lazy form. Often they are the same, but almost as often they are not. Finally, within the square brackets is the character savings per instance of the word being used correctly.

Near the bottom will be found the hint for the last word you missed. Keep The Coach open, and you can always see your most recent hint. 

At the very bottom is the progress bar. The full dictionary requires about 5 minutes to load. You can start using the Qwertigraph immediately, but it and The Coach will miss some rarer words until the dictionary is fully loaded.

#### Step: Use the Editor
This is really a whole instruction into itself, so I won't do much with it. I'll drop a couple hints here for the adventurous. 

- Double click on Editor.ahk in the Qwertigraphy folder to start the editor.
- Search in any field using regular expressions. So, to anchor your search to match only the beginning of a word or form, prepend a ^ to it. To match only the end of a word or form append a $. To match any character, use a dot. For the more experienced, all the little tricks work. 
- Double click on a row to bring it down to the editing fields. 
- Make your changes to the row and click Commit to add it back to the dictionary after corrections. 
- Click Save when you're done to write the dictionary to the file system. 
- To pick up any saved changes, you must reload the Qwertigraph. 