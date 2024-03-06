#!/usr/bin/python
cols = [0,1,3,4,7]

for col in cols:
    if col == 0:
        print("\\033[XXm  ", end = '\t')
    else:
        print("\033[%dm\\033[%d;XXm\033[2%dm" % (col, col, col), end = '\t')
print("")

for i in range(30,37+1):
    for col in cols:
        print("\033[%dm" % (col), end = '')
        print("\033[%dm%d\t\033[%dm%d" % (i,i,i+60,i+60), end = '');
        print("\033[2%dm" % (col), end = '\t')

    print("")
print("")


print("\033[39m\\033[39m - Reset colour")
print("\\033[2K - Clear Line")
print("\\033[<L>;<C>H OR \\033[<L>;<C>f puts the cursor at line L and column C.")
print("\\033[<N>A Move the cursor up N lines")
print("\\033[<N>B Move the cursor down N lines")
print("\\033[<N>C Move the cursor forward N columns")
print("\\033[<N>D Move the cursor backward N columns")
print("\\033[2J Clear the screen, move to (0,0)")
print("\\033[K Erase to end of line")
print("\\033[s Save cursor position")
print("\\033[u Restore cursor position")
print(" ")
print("\\033[4m  Underline on")
print("\\033[24m Underline off")
print("\\033[1m  Bold on")
print("\\033[21m Bold off")
