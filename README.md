# Flat-assembly-Text-editor-example
Based on the Minipad Fasm example with two additional features : 
- a save button that opens a file dialog and let the user choose a name and create a new file then write in it the content of the GUI text box
- a open button that opens a file dialog and let the user choose a file and opens it then replace the content of the GUI text box by the file content.
Requirements:
-library
kernel,'KERNEL32.DLL'
user,'USER32.DLL',
gdi,'GDI32.DLL',
commdlg,'COMDLG32.DLL'
- Having the icon file minipad.ico (case-sensitive) in the same folder as the program.
Note: The setup will be much faster with fasm , you'll just need the minipad.ico to be in the same folder
________________________________________________________________________________________________________________________________________________________________________
This examples aims to demonstrate how to interact with the text box , get it's content , change it's content , and read/write operation on files.

