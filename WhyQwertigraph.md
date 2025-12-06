### Why Qwertigraph?

[Why Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/WhyQwertigraph.md) | 
[How to Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/HowQwertigraph.md) | 
[Broken Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/FixQwertigraph.md) | 
[Customize Qwertigraph?](https://github.com/codepoke-kk/qwertigraphy/blob/master/CustomizeQwertigraph.md)

Because you are willing to work pretty hard to work smart. 

By now we were supposed to have flying cars and our computers were going to know everything we wanted them to do by a simple voice command. We were supposed to be able to tell them to "write a note to Grandma", and all our deepest feelings would show up on screen. That has not happened, and it's not going to happen. I'll never feel good about the way any computer captured my words and put them on paper. 

I need a keyboard. 

But I also need the words to show up quicker. The Qwertigraph allows me to boost my usual 60-80 WPM to 90-150 WPM. I especially feel that benefit when I'm in an instant chat with someone. I want the words to flow at the speed of speech, and hitting 150 WPM for an extended stretch is just fun. Email flows better at 100 WPM than at 60. Reports are vaguely interesting when I'm done with them 40% quicker. 

I wrote and use the Qwertigraph because it turns every typing task into a fun little game, and while I'm playing I happen to be finishing the task in a fraction of the time it would have taken anyway. I know I've spent over 1000 hours making it, hours of irritation, fury, and eventual relief, just like playing any game. It's filled my free time with programming and my work time with savings. 

I hope you find some little joy in it, too. 

#### The Qwertigraph: 
The Qwertigraph is Qwertigraphy's main engine. Once started, it runs silently in the background watching all your keyboard input. When it sees a string of keystrokes it recognizes, it deletes whatever was typed and replaces it with an expanded word. When, for example, it sees "rf" followed by an "end character" like the space bar key, it deletes that "rf", types "reference", and only then types the space bar. You typed 3 characters and 10 were output. This may sound slow, but the system has been proven to work fine with keyboard input of more than 250 WPM and expanded output of more than 600 WPM. The Qwertigraph is fast. 

The Qwertigraph can also fit your typing style. I built Qwertigraphy with a specific goal in mind. I wanted to use it to teach myself Gregg Shorthand, so I built a dictionary of 10's of thousands of abbreviations modelled after Gregg. You may like Pittman or Forkner or an abbreviation pattern that fits your unique outlook on typing. Email me. If you a dictionary, I can show you how to format it and use your shorthand theory in the Qwertigraph. 

That said, let's settle on some terms:
- Theory: A (usually pretty complex) systematic method of abbreviating words into easier to type abbreviations
- Dictionary: A canonical list of words and the abbreviations a writer will use to type them 
- Qwerd: A single abbreviation with all its subparts
-- Qwerd: The formal qwerd is the typed input of the abbreviation 
-- Word: The word is the text to be output when the qwerd is expanded
-- Form: A hyphen-delimited set of characters that shows how the word would be written in Gregg Shorthand with a pen and paper 
-- Keyer: In Gregg Shorthand, "the, there, and their" are all written the same way. In the Qwertigraph, they need to be distinguished from each other so they are written "h, hi, ho". The "i" and "o" are not a proper part of the word itself. They are the keyers that distinguish the three words. 
-- Chord: Advanced Qwertigraphers can hit every key in a qwerd simultaneously to output an entire word with one motion; the chord is the collection of keys that output that word 
-- Usage: This was originally a word's frequency in common English use. Maintaining that became a nuisance, so now it's a vague impression of how often the word appears in normal typing. 

The Qwertigraph will support your preferred theory, after a dictionary of qwerds is built for it. I love Gregg Theory, but I seem to be pretty rare in that regard. Most people see the oddities of Gregg's theory as embodied and the Qwertigraph and run away. I get that. It's a good theory, and I can defend it, but I'd rather see people pick up the Qwertigraph with their own theory than walk away because Gregg's theory is often unintuitive. 

For the remainder of this documentation, I will be giving examples using Gregg Theory. 

### The Coach: 
The Coach is always available to tell you what you could type, what you have typed, and what you could type better. 

As of this writing, the Coach always sits to the far right of the primary screen. If you need that modified, you'll have to write the change yourself or write me and request it. The code stubs are there, but I'm happy with it the way it is. 

### The Dashboard
The Dashboard lets you stop/start (and reload dictionaries) for the Qwertigraph. It also lets you store up to 3 username/password combinations. You access those by chording b1-9. I'm still tinkering with those, so I won't document it yet. Play with it to figure out which is which. 

#### But didn't I mention taking faster notes with a pen?

You will quickly learn the qwerd for the word, "and". In Qwertigraphy, that's typed "nt". It only saves one keystroke, but it does so 50 times a day for the rest of your life. Once you have "and" committed to automatic response memory, you can begin using it in your pen writing just as easily. In longhand, the word "and" requires 7 joined pen-strokes (if you're not too fancy.) Writing just "nt" instead takes your pen-load down to only 5 strokes. It's a gain. 

Gregg Shorthand reduces the "nt" of "and" to a single pen-stroke. That's 86% of your life back.

Once you've learned the Qwertigraphy representation of any word, you can take a quick look at the Dashboard learn to its Gregg shorthand representation. A hard-working longhand writer will usually take their notes at something like 25 words per minute. With Gregg, 100 WPM will be well within your reach, and the best shorthand users exceed 200 WPM. Learn Gregg, and writing will become so much fun you'll be tempted to start writing more valuable notes, notes filled with a ton more detail. 

*Qwertigraphy cannot be held responsible for such self-abuse, but it's a risk you'll have to take.*

Next: [How to Qwertigraph](https://github.com/codepoke-kk/qwertigraphy/blob/master/HowQwertigraph.md)

# The rest of this is old....

### I've replaced the AutoHotKey Qwertigraph with the PyChorder Qwertigraph. 

The new tool is written in Python, so it's theoretically no longer stuck to Windows. I've not tried it on any other platform, so you might want to avoid trying it unless you're up for some building/fixing.


### Ignore from here 
You can do 2 things to the dashboard:
- Display: Press Win-Alt-D to toggle its visibility. If you don't like it, WAD will hide it. If you want it back, hit WAD again. 
- Find: Press Win-Alt-F to find the Dashboard. The Dashboard is not set to "always visible", so various windows can and will hide it. Any window set to full screen will always hide the Dashboard. I find this the best setting. If all the windows you have on the primary screen are in window mode, hitting WAF will rearrange them off to the left such that the Dashboard is visible. It can be a little annoying to have to do this, but every other method I tried to make it work was much more annoying. I'm open to ideas. 

There are 3 areas to the Dashboard. 
- Speedometer:
-- The Speedo shows at the bottom of the Dashboard how fast you have been typing for the last 15 seconds, with your enhanced speed in larger numbers and your raw speed in smaller letters below. 
-- The Speedo also shows the "Auxilliary Keyboard" state. If you are using a full 101-key keyboard, the 17-key number pad to the side can be used as a full keyboard, too. Every letter and special character can be typed on the aux keyboard by combining keys in snazzy ways. The list of keys is in a spreadsheet in the root folder of the Qwertigraph, but it's no otherwise documented yet. If you want to use it, let me know. 
- Coming Soon:
-- The first line of this section tells you what the current qwerd you have typed will expand to if you hit an end character 
-- The next 5 lines tell you what words will be created if you add any of the 5 primary keyers to what you have already typed. This is important for overloaded Gregg qwerds like "about" and "ability" that are separated only by the "o" keyer
-- The last 6 lines tell you what word will appear if you type one of the common word enders d, t, s, g, n, or r. Gregg uses d and t both to represent the "...ed" ending, so knowing what will happen when you type each can matter, like in the words record and worked (rkd and rkt). 
- Transcript: 
-- The Transcript exists to help you learn Gregg Theory
--- Blue rows were correct and saved keystrokes
--- Olive rows were not in the dictionary, or would not save strokes
--- Red rows are opportunities from which to learn a new qwerd
--- Gold rows were written as chords, saving even more time 
-- Line 1:
--- qwerd: The actual qwerd you typed followed by a slash
--- form: The coded Gregg pen form for that rd
--- pen form: An approximation of what the word looks like in Gregg
-- Line 2:
--- word: The word into which the qwerd expanded

#### The Coach: 
I wrote this system, and I don't know all its abbreviations! These abbreviations are unique, even to Gregg, so even an accomplished Gregg user is not going to know all the default abbreviations. Everyone needs help learning how to use this system. I wrote the Coach because this stuff is hard, and I needed help. 

The Coach is there to take you through a review of your last session or your lifetime learning. At the end of each session (whether that's an hour, a day, or a week), open the Coach and click the "Filter" button. This will bring up every word captured in that session and tell you:
- Savings: The total number of keystrokes you saved in typing this word. The number will be negative if you could have saved more characters by typing its qwerd and positive if you did save characters. 
- Word/Qwerd: As stated above 
- Chord: The keys to strike at one time for advanced speed gains with this word
- Chordable: Unused
- Form: The Gregg form of the word
- Power: A ratio of the number of characters output to the number of characters input, so how much you stand to gain using this qwerd
- Saves: How many characters the Qwertigraph types for you on this qwerd
- Matches: How many times you used the qwerd
- Chords: How many times you chorded the qwerd
- Misses: How many times you could have used the qwerd and did not 
- Other: Unknown and uncoachable words to add to a dictionary 

You can use the Filter fields at the top of the form to search for and find specific words about which you are curious. These fields take "Regular Expression" filters, so they are very powerful. If you don't know regex, then just search for the characters you want and you should be fine. 

My usual technique is to filter with every field blank and then sort by clicking column headers to sort. I will look at the words on which my "Savings" were worst, and focus on them. I might also look at all my "Other" words, and focus on which of those should be added to my dictionary. 

The idea is to let the Coach tell you which words will give you the biggest return on time investment. 

#### The Editor: 
Nothing about the Qwertigraph is set in stone. Right now, it ships with the Gregg Theory built-in, but that's not set in stone. You can write your own theory and use it or you can modify the Gregg Theory to suit your own needs. 

If you want to make wholesale changes, you are best served to directly modify or create dictionary files using computer code, Excel, or a text editor. If you want to make a couple small changes on the fly, though, I recommend using the Editor. I use it several times a week. 

You can use Regular Expressions to find similar words to the one you want to change. Double click on any found row to push its values down into the edit fields at the bottom. Make the modifications you have in mind, and click "Commit" to begin using your new definition. At some point before shutting down, you must click "Save" to ensure your changes will be there forever. The Qwertigraph does NOT warn you when you are about to shut down without saving changes. 

If you select a qwerd you've found by filtering, and click the "S" button to the right, it will create a new qwerd for you as a plural. The same is true for each of the buttons. The Editor will make some attempt to follow some of the usual rules of removing silent e from the end of the word before adding "ing", but it's not consistent. Always check whether it was dumb. 

The qwerds are stored based upon the "qwerd" value. So, if a qwerd exists with the qwerd you've chosen, your new qwerd will overwrite the existing one. There is a certain flow to making sure you are not overwriting things you actually meant to be using. The Editor does keep a couple backups of the dictionary, but if you do a bunch of saves between making a mistake and noticing it, the backups may not be helpful. 

If you choose to edit a qwerd found in the core dictionary, the Editor will default to putting your change into the supplemental dictionary. I am slow to change the core dictionary, since that was provided by an authoritative source. 

Any time you modify a dictionary in the Qwertigraph's own dictionaries folder, though, you stand to lose your changes unless you understand what you are doing. Any refresh from the master copy in GitHub will always overwrite those values unless you know your way around GitHub. If you believe you're making good and necessary changes to conform to Gregg Anniversary, you are my here. Let me know, and we will get your changes into the main copy. Elsewise, I recommend putting your changes into the personal.csv dictionary in your local settings folder, or some other dictionary you add to your load list. 

There are a couple other goodies. You can modify the shapes of the Gregg Pen drawings in the Dashboard with the Strokes tab. You can enter raw qwerds and convert them to English in the Player tab. You can see what the engine is doing and has done in the Log tab. And you can modify log settings and other settings on the settings tab. I'm afraid I don't have the time and energy to write any of that up until someone feels enough need to ask me a question about them. 
