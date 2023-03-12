import 'package:moxxmpp/moxxmpp.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'helpers/xml.dart';

void main() {
  test('Test stringxml', () {
    final child = XMLNode(tag: 'uwu', attributes: { 'strength': 10 });
    final stanza = XMLNode.xmlns(tag: 'uwu-meter', xmlns: 'uwu', children: [ child ]);
    expect(XMLNode(tag: 'iq', attributes: {'xmlns': 'uwu'}).toXml(), "<iq xmlns='uwu' />");
    expect(XMLNode.xmlns(tag: 'iq', xmlns: 'uwu', attributes: {'how': 'uwu'}).toXml(), "<iq xmlns='uwu' how='uwu' />");
    expect(stanza.toXml(), "<uwu-meter xmlns='uwu'><uwu strength=10 /></uwu-meter>");

    expect(StreamHeaderNonza('uwu.server').toXml(), "<stream:stream xmlns='jabber:client' version='1.0' xmlns:stream='http://etherx.jabber.org/streams' to='uwu.server' xml:lang='en'>");

    expect(XMLNode(tag: 'text', attributes: {}, text: 'hallo').toXml(), '<text>hallo</text>');
    expect(XMLNode(tag: 'text', attributes: { 'world': 'no' }, text: 'hallo').toXml(), "<text world='no'>hallo</text>");
    expect(XMLNode(tag: 'text', attributes: {}, text: 'hallo').toXml(), '<text>hallo</text>');
    expect(XMLNode(tag: 'text', attributes: {}, text: 'test').innerText(), 'test');
  });

  test('Test XmlElement', () {
    expect(XMLNode.fromXmlElement(XmlDocument.parse("<root owo='uwu' />").firstElementChild!).toXml(), "<root owo='uwu' />");
  });

  test('Test the find functions', () {
    final node1 = XMLNode.fromString('<message><a xmlns="a" /><body>Hallo</body></message>');

    expect(compareXMLNodes(node1.firstTag('body')!, XMLNode.fromString('<body>Hallo</body>')), true);
    expect(compareXMLNodes(node1.firstTagByXmlns('a')!, XMLNode.fromString('<a xmlns="a" />')), true);
  });

  test('Test compareXMLNodes', () {
    final node1 = XMLNode.fromString('''
 <iq type='set' id='0327c373-2e34-46bd-ab7f-1274a6f7095f' to='pubsub.server.example.org' from='testuser@example.org/MU29eEZn' xmlns='jabber:client'>
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <publish node='princely_musings'>
      <item id='current'>
        <test-item  />
      </item>
    </publish>
    <publish-options >
      <x xmlns='jabber:x:data' type='submit'>
        <field var='FORM_TYPE' type='hidden'>
          <value>http://jabber.org/protocol/pubsub#publish-options</value>
        </field>
        <field var='pubsub#max_items'>
          <value>max</value>
        </field>
      </x>
    </publish-options>
  </pubsub>
</iq>
''',
    );
    final node2 = XMLNode.fromString('''
<iq type="set" to="pubsub.server.example.org" id="a">
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <publish node='princely_musings'>
      <item id="current">
        <test-item />
      </item>
    </publish>
    <publish-options>
      <x xmlns='jabber:x:data' type='submit'>
        <field var='FORM_TYPE' type='hidden'>
          <value>http://jabber.org/protocol/pubsub#publish-options</value>
        </field>
        <field var='pubsub#max_items'>
          <value>1</value>
        </field>
      </x>
    </publish-options>
  </pubsub>
</iq>
''');

    expect(compareXMLNodes(node1, node2, ignoreId: true), false);
  });
}
