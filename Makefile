
enginepath=dataengine
enginename=nepomuk-tags-engine

plasmoidpath=plasmoid
plasmoidname=nepomuk-tagged-plasmoid

servicespath=$(shell kde4-config --localprefix)/share/apps/plasma/services
operationsfile=droptag.operations

.PHONY: all install uninstall

all: uninstall clean install

clean:
	-rm $(enginename).zip $(plasmoidname).zip

uninstall:
	-plasmapkg -t dataengine -r $(enginename)
	-plasmapkg -r $(plasmoidname)
	-rm -f $(servicespath)/$(operationsfile)

install: $(enginename).zip $(plasmoidname).zip $(servicespath)
	plasmapkg -t dataengine -i $(enginename).zip
	plasmapkg -i $(plasmoidname).zip
	cp $(enginepath)/plasma/services/$(operationsfile) $(servicespath)

$(enginename).zip: $(enginepath)
	(cd $< && zip -r ../$@ .)

$(plasmoidname).zip: $(plasmoidpath)
	(cd $< && zip -r ../$@ .)

$(servicespath):
	mkdir -p $@
