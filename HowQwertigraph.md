### How to Qwertigraph!

[Why Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/WhyQwertigraph.md) | 
[How to Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/HowQwertigraph.md) | 
[Broken Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/FixQwertigraph.md)

There are two ways to go on this. If you just want to start using Qwertigraphy, download this:
(The simplest version)
https://github.com/codepoke-kk/qwertigraphy/release/trainer.exe
(To allow chorded entry - hitting all the keys in a word at once)
https://github.com/codepoke-kk/qwertigraphy/release/chorder.exe

Double click and go!

If you'd like to see how it works, change a couple things, or steal the code and make something better:

#### Step: Download AutoHotkey 
https://www.autohotkey.com/download/

#### Step: Install AutoHotkey 
https://www.autohotkey.com/docs/AutoHotkey.htm

AutoHotkey will not do anything when you install it. After installation, it awaits your command to run a script. 

#### Step: Download Qwertigraphy
If you are familiar with the ideas and uses of GitHub, you can go to the repository and clone, pull, or download at will. If all that was Greek to you, then download a zip file of the repository here. Unzip it anywhere you'd like on your computer. I keep mine in a qwertigraphy folder in "My Documents."
https://github.com/codepoke-kk/qwertigraphy/archive/master.zip

A low-quality video walk-through here: [Qwertigraphy Quick Start](https://www.youtube.com/watch?v=Eodl0zzjCcw&feature=youtu.be)

#### Step: Start the Qwertigraph
Go to the /qwertigraph folder, and double click trainer.ahk. You should see the qwertigraph interface appear. Move it around as you wish. 

#### Step: Use the Qwertigraph
Open a simple text editor, a new email, or anything else into which you might wish to type some text. Type "It's time to start". If all has gone well, The Coach should show how quickly you typed that line. You may have noticed some recommendations flash just below your blinking cursor as you typed. Click the button in the top right of The Coach, and it should show you on which words you lost time, and what you could type instead to save that time in the future. 

Now type "T's tm to stat"

If you click the button again, The Coach should now show you've saved and lost the same number of characters, for a grand total of 0. 

Now, go forth and type like usual. At the end of the day, come back to the coach to see which words you would profit most from learning. Click the "Savings" column header to sort your possible savings from lowest to highest, and start learning from the top. 

##### Tips:
- No word will expand until you stroke an "end character". You have to hit some punctation key to let the Qwertigraph know you're done and ready to move on. 
- Control-Backspace is your friend. If you meant some other word than the one the Qwertigraph typed, Control-Backspace will delete the entire word and let you start over again. (It's much lazier to hit Control-Backspace once than to hit Backspace a does times.)
- Control-Windows-P will Pause the Qwertigraph if you need to type without its help. Control-Windows-P again will reactivate it. 
- Hitting the Control key will cause the Qwertigraph to ignore whatever word you just typed and start listening all over again.
- If you type out a word for which there's a "big win" lazy form, a pop-up tip will give you a hint to that effect. 

##### Words about letters
Gregg Shorthand users and non-users will both have questions about why some of the lazy forms are spelled the way they are. I'll do that explanation some other day, but for now I'll supply these little hints.
- **h:** Stands in for the TH sound as in THE
- **z:** Stands in for the SH sound as in SHIP
- **c:** Stands in for the CH sound as in WHICH
- **w:** Stands in for the OW sound as in POWER
- **y:** Stands in for the OY sound as in JOIN
- **q:** Stands in for the QU sound as in QUICK, or for INK, ANK, UNK as in LINK
- **u:** Usually only for long U or OO as in LOOK
- **i:** Only for the long I sound as in PIPE
- **a:** Seldom for AH and often for I (Gregg reasons)
- **e:** Stands in for many sounds like "i" in QUICK
- **t:** Often stands in for "ED" as in WORKED
- **g:** Stands in for ING, ONG, or UNG

##### Keyers
Gregg Shorthand uses exactly the same form for several words. For example, THE, THERE, and THEIR are all lazified using the H, which is the TH sound. The Qwertigraph needs to know which of those words the Qwertigrapher means, so they are keyed using vowels. The most commonly used word is THE, so a pure H is the word THE. Adding an O to the H makes the word THEIR. Adding an I to the H makes THERE. You will see many Qwertigraphy words that end with O, U, and I. You will see a few ending in E, A, W, and Y. These are often keyed words. Whenever you see one, you can bet there's an unkeyed lazy form already representing some more frequently used word. 

You can always tell the actual Gregg Shorthand form by looking at The Coach or The Editor. The "form" is exactly how the word is written in Gregg.

#### Step: Use The Coach
##### Click "Search" in the top right, after typing for a while to see a sortable, filterable (someday) list of all the words you've typed in this session. 

More can and should be written about this, but I'm too tired tonight. I rewrote The Coach from the ground up, and the whole documentation thing needs a total rework some day soon.

#### Step: Use the Editor
This is really a whole instruction into itself, so I won't do much with it. I'll drop a couple hints here for the adventurous. 

- Search in any of the top fields using regular expressions. So, to anchor your search to match only the beginning of a word or form, prepend a ^ to it. To match only the end of a word or form append a $. To match any character, use a dot. For the more experienced, all the little tricks work. 
- Double click on a row to bring it down to the editing fields. 
- Make your changes to the row and click Commit to add it back to the dictionary after corrections. 
- Click Save when you're done to write the dictionary to the file system. 