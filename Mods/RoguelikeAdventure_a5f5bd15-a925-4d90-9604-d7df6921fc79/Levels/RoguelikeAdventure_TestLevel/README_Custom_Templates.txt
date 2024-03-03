Creating custom templates
==========================

It is possible to define a level as a template so the editor browser automatically loads it next to the other templates in the "New" tab when Loading/Creating a level.
This level (Basic) is set up like that, as an example.

In terms of steps, do the following:

1. 	Go to the editor folder of the level (Data/Editor/Mods/YourMod/Levels/YourLevel) and look for the following attribute line in EditorMetaData.lsx:
		<attribute id="IsTemplate" value="0" type="19" />
	Make sure the value is set to "1" instead of "0"
	*TODO* You can also easily set this in the editor

2.	Customize how your level is shown in the browser by adding thumbnails in the Data folder of the level (Data/Mods/YourMod/Levels/YourLevel)
	Custom banner (bottom image): 		banner.png
	Custom thumbnail (button image): 	templateThumbnail.png

That's it! Enjoy!