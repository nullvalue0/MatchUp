# MatchUp
A matchup / "memory" card game developed in x86 asm that fits in a 512 byte boot sector

This is a game I developed for the purpose of teaching myself x86 assembly. Learning assembly has been a goal of mine for a long time now and the coronavirus quarantine provided an excellent opportunity to get started. A huge thanks to Oscar Toledo (https://github.com/nanochess) for his book “Programming Boot Sector Games” and his personal help along the way when I got stuck.

This game is like the “memory” card game in that a deck of flipped-over cards are presented. You flip over two at a time looking for a match. You win when you uncover all of the matches. The compiled version of this game provides cards in a 6x4 grid (24 cards total). The code supports recompiling up to an 8x6 grid (48 cards total), or a smaller grid so long as the gridWidth*gridHeight equals an even number.

I first developed the game in QBASIC – a language I am already familiar with. I did this so that I knew exactly what I wanted the game to do first before attempting to port it to assembly. I have provided that version of the game (MATCHUP.BAS) here as well.

The assembly version has been developed for the NASM (The Netwide Assembler). The DOS-executable COM file has some additional features such as sound, a title, and a nicer looking grid. All that needed to be stripped out to get it to fit onto a floppy boot sector. You can write this to an actual floppy disk or use qemu to try out the boot sector version: qemu-system-x86_64 -fda matchup.img
