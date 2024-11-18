# ----------------------------
# TODO: Fill your group number, your NOMAs and your names
# group number X
# 95922200 : Loïs Djembi
# 71312200 : Julien Renard
# ----------------------------
UNAME_S := $(shell powershell -Command "(Get-WmiObject Win32_OperatingSystem).Name")

ifeq ($(findstring Windows, $(UNAME_S)), Windows)
    OZC = ozc
    OZENGINE = ozengine
    RM = del /Q
else
    OZC = /Applications/Mozart2.app/Contents/Resources/bin/ozc
    OZENGINE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine
    RM = rm -rf
endif

all:
	$(OZC) -c Input.oz -o "Input.ozf"
	$(OZC) -c Trainer000Template.oz -o "Trainer000Template.ozf"
	$(OZC) -c AgentManager.oz
	$(OZC) -c Graphics.oz
	$(OZC) -c Main.oz

run:
	$(OZENGINE) Main.ozf

clean:
	$(RM) *.ozf
