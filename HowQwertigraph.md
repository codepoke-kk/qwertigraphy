### How to Qwertigraph!

[Why Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/WhyQwertigraph.md) | 
[How to Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/HowQwertigraph.md) | 
[Broken Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/FixQwertigraph.md) | 
[Customize Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/CustomizeQwertigraph.md)

There are two ways to go on this. If you just want to start using Qwertigraphy, download this:
(To allow chorded entry - hitting all the keys in a word at once)
https://github.com/codepoke-kk/qwertigraphy/release/chorder.exe

Double click and go!

### Reality Check 
If you are reading these words, please understand this poor tool has received much more attention from me than from anyone else on earth, and I never needed these hints how to proceed. They are incomplete, because no one has ever really needed them. You can try emailing me with questions, and I will be happy to answer when the time makes itself available. 

And, I have to admit the dictionary is only 95% complete, even for me. I mean to say, 95% of the words I need are in there. Every day I find the word I need thousands of times, but a dozen times a day the word I need is not in there. And I may not need that word again for another year or two, so I don't just jump up and add it. And then it's missing the next time I need it, too. The Coach helps me find those words, but I'm busy actually typing all day long, and don't always enter the words the Coach is coaching me to use. 

And, I know the qwerds look like utter nonsense sometimes. My chief goal in this process is to end up with a fully compliant Gregg Anniversary dictionary, and sometimes Gregg looks like nonsense. That's my desire, and in 2 years I've not wavered from it. Gregg says "re" is "real" while "reality" is "rel", so that's what the Qwertigraph will say. It looks silly, but that's me for you. Your author of this product is just silly.

The Qwertigraph is a tool, a framework. You, or anyone else can create your own dictionary of cooler and more efficient qwerds. Maybe you like Teeline or Pitman? The Qwertigraph can do them. Maybe you have your own idea of the most efficient way to structure a brand new Shorthand. The Qwertigraph can do that. If you have such a dream, drop me a line and I'll help you make your dictionary happen. And if you want to pair it with pen shorthand changes, I can show you how to make that happen, too. It ain't easy, but it's possible and fun.  

Lastly, If you'd like to see how the code works, change a couple things, or steal the code and make something better:

I followed exactly these steps to get the system up and running on my second laptop and they worked. You'll get no closer to a guarantee from me. 

#### Step: Install Python 
You'll need version 3.12, 3.13, or 3.14. 

#### Step: Install Poetry
Just pip install poetry. Nothing fancy. Take all the upgrades you like.

#### Step: Download Qwertigraphy
If you are familiar with the ideas and uses of GitHub, you can go to the repository and clone, pull, or download at will. If all that was Greek to you, then download a zip file of the repository here. Unzip it anywhere you'd like on your computer. I keep mine in a qwertigraphy folder in "My Documents."
https://github.com/codepoke-kk/qwertigraphy/archive/master.zip

A low-quality (and very dated at this point) video walk-through can be found here. Replace all references to "trainer" with "chorder" as you watch and listen: [Qwertigraphy Quick Start](https://www.youtube.com/watch?v=aPxECydje50)

#### Step: Get the Qwertigraph running 
You'll need to install a virtual environment in which the Qwertigraph can run. 

> poetry install --no-root
Installing with no root is what I'm doing now. If I ever decide to package this due to overwhelming demand for the Qwertigraph, I'll pick my jaw up off the floor and do so. For now, I do this the hard way.

> .venv/Scripts/Activate
This will put your command prompt into the virtual environment and set you up to run the Qwertigraph.

> python .\qw.py
This will launch the Qwertigraph in fully active mode. You can pre-load some credentials into the visible fields or just start typing into any application. You should immediately see the characters you're typing show up in the coach to the right side of your screen. 




# The rest of this is old....

### I've replaced the AutoHotKey Qwertigraph with the PyChorder Qwertigraph. 

The new tool is written in Python, so it's theoretically no longer stuck to Windows. I've not tried it on any other platform, so you might want to avoid trying it unless you're up for some building/fixing.


### Ignore from here

#### Step: Download AutoHotkey 
https://www.autohotkey.com/download/

#### Step: Install AutoHotkey 
https://www.autohotkey.com/docs/AutoHotkey.htm

AutoHotkey will not do anything when you install it. After installation, it awaits your command to run a script. 

#### Step: Download Qwertigraphy
If you are familiar with the ideas and uses of GitHub, you can go to the repository and clone, pull, or download at will. If all that was Greek to you, then download a zip file of the repository here. Unzip it anywhere you'd like on your computer. I keep mine in a qwertigraphy folder in "My Documents."
https://github.com/codepoke-kk/qwertigraphy/archive/master.zip

A low-quality (and very dated at this point) video walk-through can be found here. Replace all references to "trainer" with "chorder" as you watch and listen: [Qwertigraphy Quick Start](https://www.youtube.com/watch?v=aPxECydje50)

#### Step: Start the Qwertigraph
Go to the /qwertigraph folder, and double click chorder.ahk. You should see two qwertigraph interfaces appear. You can move the boxy-looking Log interface around as you wish. The Dashboard interface will appear glued to the right side of your primary monitor. Yes, it could be made movable, but I've not yet had the request or the time to do so. Drop me a line if I could make it better. 

I use the Dashboard a lot, and I expect you will too, but it was important not to make it "always on top", because that breaks much more than it fixes. The compromise I've settled upon for now is to make it retrievable. Any "Maximized" window will cover it up. This is a good thing. When I don't care to use the Dashboard, I just maximize whatever I'm working on and am glad it's not there. If, however, I want to see the Dashboard while I work I have to make the current window resizable. After that, I can click "Win-Alt-F" to let the Qwertigraph automatically position the window I'm working in pretty near to the Dashboard. It's still a bit wonky, but it works and I am happy enough with it for now. 

#### Step: Use the Qwertigraph
Open a simple text editor, a new email, or anything else into which you might wish to type some text. Type "It's time to start". If all has gone well, the Dashboard should show in red numbers how quickly you typed that line, and it should show the same number twice. This is because the system did not expand any qwerds, so your input and output were the same. You should also notice some red marks in the Dashboard, as it tries to tell you these are words you could have typed faster. 

Now type:

> T's tm to stat

The Dashboard now should show a little difference between the bottom red number and the top, because the Qwertigraph expanded 3 qwerds. Your document should have the same sentence twice, because the Qwertigraph expanded those three qwerds into the same 3 words. Lastly, the Dashboard should show 4 blue tips (success) and 1 gold tip (your way of typing "to" was as fast as the Gregg way).

Now, go forth and type like usual. At the end of the day, come back to the Qwertigraph GUI and click the Coach tab to see which words you would profit most from learning. Click the "Savings" column header to sort your possible savings from lowest to highest, and start learning from the top. 

##### Tips:
- No word will expand until you stroke an "end character", like the space bar, the period symbol, or most other punctuation. You have to hit some punctation key to let the Qwertigraph know you're done and ready to move on. 
- Control-Backspace is your friend. If you meant some other word than the one the Qwertigraph typed, Control-Backspace will delete the entire word and let you start over again. (It's much lazier to hit Control-Backspace once than to hit Backspace a dozen times, and I'm lazy.)
- Control-Backspace is also a big reset key. The Qwertigraph keeps a little buffer of the last several words you typed, and if you backspace 12 times, then turn whatever's left into the qwerd you want, it will often be able to expand that qwerd. It's kind of like magic. Control-backspace empties that buffer. This is for two reasons. The important one is that the magic it's like is sometimes black magic. Hitting a number of backspaces then typing something will sometimes cause the Qwertigraph to think it's clever enough to expand some qwerd that's really just an artifact of its own confusion. Control-backspace can resolve some confusion for the poor Qwertigraph engine. 
- Windows-Alt-P will Pause the Qwertigraph if you need to type without its help. Windows-Alt-; will reactivate it. 
- Hitting the Control-space key key will cause the Qwertigraph to leave whatever word you just typed without expanding it, and start listening all over again. So will clicking the mouse. 
- The semicolon (;) is the "glue" character. If you type 2 words separated by a semicolon, instead of a space, the semicolon will be deleted and the 2 words will be glued together. You can use that for writing hashtag-type words or using prefixes and suffixes.

##### Words about Gregg Theory
Gregg Shorthand users and non-users alike will have questions about why some of the qwerds are spelled the way they are. I'll do that explanation some other day, but for now I'll supply these little hints.
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
Gregg Shorthand uses exactly the same pen form for several words. For example, THE, THERE, and THEIR are all written using the H, which is the TH sound. The Qwertigraph needs to know which of those words the Qwertigrapher means, so they are keyed using vowels. The most commonly used word is THE, so a pure H is the word THE. Adding an O to the H makes the word THEIR. Adding an I to the H makes THERE. You will see many Qwertigraphy words that end with O, U, and I. You will see a few ending in E, A, W, and Y. These are often keyed words. Whenever you see one, you can bet there's an unkeyed qwerd already representing some more frequently used word. 

There are a few hyphenated words in the dictionary. Prefixed, hyphenated words use a 'qq' as the keyer whenever possible (e.g. fqq for "photo-") and suffixed, hyphenated words use a 'pp' as the keyer (e.g. dpp for "-hood"). Think of the "q" as being at the left side of the keyboard and the "p" as being on the right side to remember that.

You can always tell the actual Gregg Shorthand form by looking at The Coach or The Editor. The "form" is exactly how the word is written in Gregg.

#### Step: Use The Coach
##### Click "Search" in the top right, after typing for a while to see a sortable, filterable list of all the words you've typed in this session. You can sort this list by any of the column headers, to seek out specific information, like which word you typed most. 

More can and should be written about this, but I'm too tired tonight. I rewrote The Coach from the ground up, and the whole documentation thing needs a total rework some day soon.

#### Step: Watch the Dashboard 
##### The Dashboard shows you what the word you just typed will look like when when written with a pen. It's clunky and jagged compared to real Gregg Shorthand, but the idea is about right. It will also show you the qwerd for the last several words you just typed. This is its greatest value to the casual typist.

Be sure to check out the predictive, bottom portion of the Dashboard. It will tell you what words will be expanded if you add one of 11 different letters to what you've already typed.

#### Step: Use the Editor
This is really a whole instruction into itself, so I won't do much with it. I'll drop a couple hints here for the adventurous. 

- Search in any of the top fields using regular expressions. So, to anchor your search to match only the beginning of a word or form, prepend a ^ to it. To match only the end of a word or form append a $. To match any character, use a dot. For the more experienced, all the little tricks work. 
- Double click on a row to bring it down to the editing fields. 
- Make your changes to the row and click Commit to add it back to the dictionary after corrections. 
- Click Save when you're done to write the dictionary to the file system. 
