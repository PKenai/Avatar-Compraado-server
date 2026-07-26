#!gdb
import gdb
from datetime import datetime

tfsbin = "theforgottenserver"

def crash(event):
    if (isinstance(event, gdb.SignalEvent)):
        logfile = "data/logs/crashs/" + str(datetime.now().strftime("%d-%m-%Y-%H-%M-%S")) + ".txt"
        file = open(logfile, "a+")
        file.write("---------------------------------------------------\nSignal caught: " + event.stop_signal + " in " + str(datetime.now().strftime("%d/%m/%Y - %H:%M:%S")) + "\n")
        file.close()
        gdb.execute("set pagination off")
        gdb.execute("set confirm off")
        gdb.execute("set logging file " + logfile)
        gdb.execute("set logging on")
        gdb.execute("set logging redirect on")
        gdb.execute("thread apply all bt full")
        gdb.execute("call g_game.saveGameState()")
        gdb.execute("set logging off")
        gdb.execute("set logging redirect off")
        gdb.execute("generate-core-file")
        gdb.execute("kill")
        gdb.execute("run")

gdb.events.stop.connect(crash)
gdb.execute("file " + tfsbin)
gdb.execute("run")
gdb.execute("quit")
