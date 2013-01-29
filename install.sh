#!/bin/sh

set -x

enginepath=dataengine
enginename=nepomuk-tagged-engine

plasmoidpath=plasmoid
plasmoidname=nepomuk-tagged-plasmoid

servicespath=`kde4-config --localprefix`share/apps/plasma/services
operationsfile=nepomuk_tagged_service.operations

case $1 in
    uninstall)
	plasmapkg -t dataengine -r $enginename
	plasmapkg -r $plasmoidname
	rm -f $servicespath/$operationsfile
        ;;
    * | install)
	(cd $enginepath && zip -r ../$enginename.zip .)
	(cd $plasmoidpath && zip -r ../$plasmoidname.zip .)
	plasmapkg -t dataengine -i $enginename.zip
	plasmapkg -i $plasmoidname.zip
	mkdir -p $servicespath
	cp $enginepath/plasma/services/$operationsfile $servicespath
	rm $enginename.zip $plasmoidname.zip
esac
