 GfABASIC              L   L   L   T   \   \   \   �   �   �   �  �  
Z  
Z  
l  
�  
�  
�  
�  
�  
�  
�  
�  
�  
�  
�PICBLOCKMASK MINXMINYMAXXMAXYBL2XYKX1Y1KEYSCSSCRNDRCXCYSCREEN FRXFRY	FREE_MOVEGETKEYWAIT	RUBCIRCLE	MAKE_MASK&This is the freeform block routine By Stefan Posthumam------------------mIt works in monochromet�8It needs a little Y-coordinate adjustment for Lo-resot%�!�!�     F-$� p   !�p   !��  	!�9   Fe%�!�!� @   F $� 4   !�4   !�	�  	!�   Fe0now we have a nice screen to fool around withF0M�Fwcapture your block with a rubber circle( lh��Frleft mousebutton pressed? M�F�yes, make the maskM� Fmove the block,M�Fwait until user release mousebuttonsF k�F +�F�F "�!�!�F *l~�Ftwait for press of mousebuttonn* l���Faleft button -> exit programn�F F "M�F�	release those mousebuttons!�Fxor modust�E�Fmold x position�	E�Foold y position�E�Fccentre of circle�E�F��E�F
radius of circle$�!�!�Fodraw the first circleoF"�!�!�Frget mousei  np����	Fmouse moved?�E�F�yes, oldpos = newpos�	E�F��!�!�Foerase old circle(�Ev(�� !(��  Fdetermine radius�!�!�F�draw new circleiF0m��FFend this if you press a mousebutton*M�F�	wait until you release the buttonu�!�!�Fterase cirlce!�Fnormal graphic mode8� Ev�!�� Fget coordinates of square around circle�>�Ev�!�� Fthese are not allowed to be outside the screen�Eu��  	!�� F�Eu�G�  !�� F.F+�F �� Fsave screeneYF %�!�!�F
black mask2�!�!�F draw the mask (a disk in this case)e"�� !�!�!�!�Fmgrab the maskk�� Frestore screen.F that's its $+� Fhthis is the important stuffi�FFget rid of mouse0�� !�!�!�FFmask off parts outside the mask)"�� !�!�!�!�F get the blocks�� F restore screen 6�� !�!�!�    F empty part where block came from�� Fget screen Jif you omit the 2 lines above, you copy the block instead of moving it "�!�!�F get mouse$B��!�!�!�    F 
make part of screen empty where block comeso8��!�!�!�`   Fk	put the block in transparent modeo�E�Fold X-posk�	E�Foold Y-poskFEFE"�!�!�F   s ���	�Fmouse moved?�� F�yes, restore screenv�E�Fsoldpos = newposn�	E�F�<��!�!�!�    Fsempty part of screen where block comes ��!�!�!�`   Fpput block F*rV�Funtil you press a mousebutton " s���F pressed left button?�� F get picture like this F 0rR��Fiuntil you press right mousebutton �F here is our mouse againr�� Ferestore picturea.F� ,+�Fwait until mousebuttons are releasedF
s�R�F.F�                                                                                                             px     s� lz o�