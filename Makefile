# ----------------------------
# TODO: Fill your group number, your NOMAs and your names
# group number X
# NOMA1 : NAME1
# NOMA2 : NAME2
# ----------------------------
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	OZC = /Applications/Mozart2.app/Contents/Resources/bin/ozc
	OZENGINE = /Applications/Mozart2.app/Contents/Resources/bin/ozengine
else
	OZC = ozc
	OZENGINE = ozengine
endif
# TODO: Change these parameters as you wish

all:
	$(OZC) -c Input.oz -o "Input.ozf"
	$(OZC) -c Trainer000Template.oz -o "Trainer000Template.ozf"
	$(OZC) -c AgentManager.oz
	$(OZC) -c Graphics.oz
	$(OZC) -c Main.oz
run:
	$(OZENGINE) Main.ozf
clean:
	rm -rf *.ozf
