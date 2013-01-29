# -*- coding: utf-8 -*-

from PyQt4.QtCore import QObject, QVariant, QUrl, QByteArray, QString
from PyKDE4.akonadi import Akonadi
from PyKDE4.nepomuk import Nepomuk
from PyKDE4.soprano import Soprano
from PyKDE4.plasma import Plasma
from PyKDE4.plasmascript import DataEngine
from PyKDE4.kdecore import KUrl

def isFlaggedMessage(url):
    it = Akonadi.Item.fromUrl(url)
    job = Akonadi.ItemFetchJob(it)
    job.fetchScope().fetchFullPayload()
    if job.exec_():
        for item in job.items():
            if QByteArray('\\FLAGGED') in item.flags():
                return True
    return False

def getResources(tagName):
    prefix = 'PREFIX nao: %(nao)s PREFIX rdfs: %(rdfs)s PREFIX xls: %(xls)s ' % {
        'nao': Soprano.Node.resourceToN3(Soprano.Vocabulary.NAO.naoNamespace()),
        'rdfs': Soprano.Node.resourceToN3(Soprano.Vocabulary.RDFS.rdfsNamespace()),
        'xls': Soprano.Node.resourceToN3(Soprano.Vocabulary.XMLSchema.xsdNamespace())
    }
    query = \
          'select distinct ?r where { \
           ?r nao:hasTag ?tag . \
           ?tag rdfs:label %(tagName)s . \
           optional { ?tag nao:created ?tagCreated . } . \
           optional { ?r nie:lastModified ?contentLastModified . } \
           } ORDER BY DESC(?tagCreated) DESC(?contentLastModified)' % {
              'tagName': Soprano.Node(tagName).toN3(),
          }
    model = Nepomuk.ResourceManager.instance().mainModel()
    iterator = model.executeQuery(prefix + ' ' + query, Soprano.Query.QueryLanguageSparql)
    if iterator.isValid():
        resources = []
        while iterator.next():
            node = iterator.binding('r')
            resource = Nepomuk.Resource.fromResourceUri(KUrl(node.uri()))
            resources.append(resource)
        return resources
    else:
        return None

class NepomukTagDataEngine(DataEngine):

    def __init__(self,parent,args=None):
        DataEngine.__init__(self, parent)

    def sources(self):
        return [tag.label() for tag in Nepomuk.Tag.allTags()]

    def sourceRequestEvent(self, name):
        return self.updateSourceEvent(name)

    def updateSourceEvent(self, label):
        if not label in self.sources():
            return False
        self.removeAllData(label)
        for resource in Nepomuk.Tag(label).tagOf():
            data = {
                u'uri': resource.uri(),
                u'label': resource.label(),
                u'genericIcon': resource.genericIcon(),
                u'type': QUrl(resource.type()).fragment(),
            }
            nepomukResource = Nepomuk.Resource.fromResourceUri(KUrl(resource.uri()))
            if nepomukResource.hasProperty(Soprano.Vocabulary.NAO.description()):
                data[u'description'] = nepomukResource.property(Soprano.Vocabulary.NAO.description()).toString()
            for key in resource.properties().keys():
                value = resource.property(key).variant()
                if key.fragment() == u'from':
                    contact = Nepomuk.Resource(value.toUrl())
                    value = contact.property(Nepomuk.Vocabulary.NCO.fullname()).toString()
                if not key.fragment() in [u'plainTextMessageContent', u'fileContent']:
                    data[key.fragment()] = value
            self.setData(label, resource.uri(), QVariant(data))
        return True

    def serviceForSource(self, name):
        if name in self.sources():
            return DropTagService(self, name)
        return Plasma.DataEngine.serviceForSource(source)


class DropTagService(Plasma.Service):

    def __init__(self, parent, tagName):
        Plasma.Service.__init__(self, parent)
        self.tagName = tagName
        self.setName("nepomuk_tagged_service")

    def createJob(self, operation, parameters):
        if (operation == "remove"):
            return DropTagJob(self, parameters)
        return None


class DropTagJob(Plasma.ServiceJob):

    def __init__(self, service, parameters):
        self.tagName = service.tagName
        ressourceUrl = parameters[QString(u'ressource')].toString()
        Plasma.ServiceJob.__init__(self, ressourceUrl, "remove", parameters, service)

    def start(self):
        print "DropTagJob.start", self.destination(), self.tagName
        resource = Nepomuk.Resource.fromResourceUri(KUrl(self.destination()))
        tags = resource.tags()
        tag = Nepomuk.Tag(self.tagName)
        if tag in tags:
            tags.remove(tag)
            resource.setTags(tags)
            self.setResult(True)
        else:
            self.setResult(False)


def CreateDataEngine(parent):
    return NepomukTagDataEngine(parent)
