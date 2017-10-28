
# SP_SwingTimer

Author: EinBaum (known as Bulldozer @ Emerald Dream)

### About

Swing timer bar for melee autoattacks using one weapon.

Two weapons are not guaranteed to work correctly.

### Features

Confirmed to work with the following classes: Warrior, Hunter, all casters

- Attempts to calculate swing timer after Parry. Info: http://www.wowwiki.com/Parry
- Bar color changes when the remaining swing time is lower than the casting time of Slam.
- Support for switching weapons during combat

### Settings

	General help and info:
		/st

	Get bar X-position:
		/st x

	Get bar Y-position:
		/st y

	Change x-position:
		/st x [number]

	Change y-position:
		/st y [number]

	Get bar W(idth):
		/st w

	Get bar H(eight):
		/st h

	Change width:
		/st w [number]

	Change height:
		/st h [number]

	Change alpha:
		/st a [number] *(between 0-1)*

	Get scale:
		/st s

	Change scale:
		/st s [number]

	Reset default bar position and size (x=0, y=-100, w=500, h=15):
		/st reset

	Show the timer. For testing only.
		/st show

### SLAM MACRO.txt

This spammable macro will only cast Slam if the swing timer has just been reset after an auto attack.
