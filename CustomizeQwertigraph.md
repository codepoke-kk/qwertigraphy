### Customizing the Qwertigraph

You say you don't like Anniversary Gregg Shorthand, but you don't want to write your own Qwertigraph? You're in luck. You can throw out the default dictionaries, and create your own with common sense, panache, and deep efficiency. The Qwertigraph is your playground!

The Qwertigraph is controlled by layers of dictionaries. Each dictionary will contain its own entries built to its own theory. Replace the dictionaries and the Qwertigraph is your own.  

The dictionaries do not need all to conform to the same theory, and they do not need to worry about having conflicting entries for the same qwerds. The first dictionary to define a qwerd reserves it from all further use. To make use of this feature, order the load of your dictionaries such that higher priority definitions are loaded first. 

#### Controlling your dictionaries 

The "dictionary load list" is found in your personal Qwertigraphy data folder. To open this folder, start the Qwertigraph and go to its "Editor" tab. The second button down on the right side is "Personalizations". Click it to open the folder. 

Within your personal data folder, you will find "dictionary_load.list". That file begins life with these contents:
> AppData\personal.csv
> dictionaries\anniversary_core.csv
> dictionaries\anniversary_supplement.csv
> dictionaries\anniversary_phrases.csv
> dictionaries\anniversary_modern.csv
> dictionaries\anniversary_cmu.csv

My recommendation is that you create all your dictionaries in your personal data folder, and then list them in the load list just like the personal.csv dictionary is listed. There is no limit to the number of dictionaries you can create and order here. One possible example of an entirely new theory might look like:
> AppData\pittman_supplement.csv
> AppData\pittman_phrases.csv
> AppData\pittman_core.csv

(As of this writing, your Pittman dictionary will not draw Pittman forms on the "Gregg" tab. If you want it to do that for you, you can override the strokes.ahk drawing file to create new shapes.)

You must then create your dictionary files. Your dictionary should look like this:
> word,form,qwerd,keyer,chord,usage
> red,qwer,qwer,,eqrw,1
> orange,asdf,asdf,,adfs,1
> yellow,zxcv,zxcv,,cvzx,1
> green,qwe,qwe,,eqw,1
> blue,sdf,sdf,,dfs,1
> surely you must be expecting purple.,xcv,xcv,,cvx,1
> this is amazing progress;,dfjk,dfjk,,dfjk,1
> i am very excited!,fghj,fghj,,fghj,1
> do you think it will work?,cvm,cvm,,cmv,1
> (is this list too long?),vbnm,vbnm,,bmnv,1

The first line is a hint regarding what each row contains. The dictionary is called a CSV file, but it does not comply with normal CSV standards. The first line does not really define the way the fields are used. You can modify that line at will, but it must be there. The second difference is that the Qwertigraph does not respect quotation marks as a way of hiding commas. You can put a lot of punctuation in your dictionary, but commas are not yet allowed. I should probably work on that. 

The fields must be defined as follows:
- Word: Almost anything without a comma. This is the output you want after you type your qwerd or brief.
- Form: This defines the way the Gregg Pad will draw the qwerd you type. Look at other dictionaries to see what that should look like, but it's hyphen-delimited.
- Qwerd: The characters that must be typed one character at a time and ended with an end character in order to make the Qwertigraph expand it into the word you want.
- Keyer: Where you need to add a meaningless character to the end of your qwerd to distinguish it from a previously defined qwerd, identify the character you chose here. Used in some analyses somewhere.
- Chord: The characters that must all be struck and released in a single motion in order to make the Qwertigraph expand it into the word you want. The chord must appear with the characters in alphabetical order and with no repeated characters. (You cannot chord a single key twice). 
- Usage: A vague number indicating how often you expect to use this word in your system. The number started life as the Wikipedia ranking of words from most to least frequent in the English language. 

When your dictionary is right and your load list contains all the dictionaries you want to use, restart the Qwertigraph and give it a whirl. If things don't go as expected, you can try going to the Settings tab of the Qwertigraph and turning the logging of the Dictionary Map up to 4 and see whether any of the gibberish appearing there gives you any clues. Log spelunking is dangerous and I cannot be responsible for any emotional scarring incurred in the attempt.

If your theory reaches the point you'd like to see it published to the masses, we can create an option to publish it from the GitHub. 