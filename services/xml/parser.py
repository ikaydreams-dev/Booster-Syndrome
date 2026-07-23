import xml.etree.ElementTree as ET
from typing import Dict, Any, List, Optional

class XMLParser:
    @staticmethod
    def parse_file(filepath: str) -> ET.Element:
        tree = ET.parse(filepath)
        return tree.getroot()

    @staticmethod
    def parse_string(xml_string: str) -> ET.Element:
        return ET.fromstring(xml_string)

    @staticmethod
    def to_string(element: ET.Element, encoding: str = 'unicode') -> str:
        return ET.tostring(element, encoding=encoding, method='xml')

    @staticmethod
    def to_dict(element: ET.Element) -> Dict[str, Any]:
        result = {}

        if element.attrib:
            result['@attributes'] = element.attrib

        if element.text and element.text.strip():
            if len(element) == 0:
                return element.text.strip()
            result['#text'] = element.text.strip()

        children = {}
        for child in element:
            child_data = XMLParser.to_dict(child)

            if child.tag in children:
                if not isinstance(children[child.tag], list):
                    children[child.tag] = [children[child.tag]]
                children[child.tag].append(child_data)
            else:
                children[child.tag] = child_data

        result.update(children)

        if len(result) == 1 and '#text' in result:
            return result['#text']

        return result

    @staticmethod
    def from_dict(data: Dict[str, Any], root_tag: str = 'root') -> ET.Element:
        element = ET.Element(root_tag)

        XMLParser._dict_to_element(element, data)

        return element

    @staticmethod
    def _dict_to_element(parent: ET.Element, data: Any) -> None:
        if isinstance(data, dict):
            for key, value in data.items():
                if key == '@attributes':
                    parent.attrib.update(value)
                elif key == '#text':
                    parent.text = str(value)
                elif isinstance(value, list):
                    for item in value:
                        child = ET.SubElement(parent, key)
                        XMLParser._dict_to_element(child, item)
                else:
                    child = ET.SubElement(parent, key)
                    XMLParser._dict_to_element(child, value)
        else:
            parent.text = str(data)

    @staticmethod
    def find(element: ET.Element, path: str) -> Optional[ET.Element]:
        return element.find(path)

    @staticmethod
    def find_all(element: ET.Element, path: str) -> List[ET.Element]:
        return element.findall(path)

    @staticmethod
    def get_text(element: ET.Element, path: str, default: str = '') -> str:
        found = element.find(path)
        return found.text if found is not None and found.text else default

    @staticmethod
    def get_attribute(element: ET.Element, name: str, default: str = '') -> str:
        return element.get(name, default)

    @staticmethod
    def set_text(element: ET.Element, path: str, text: str) -> None:
        found = element.find(path)
        if found is not None:
            found.text = text

    @staticmethod
    def set_attribute(element: ET.Element, name: str, value: str) -> None:
        element.set(name, value)

    @staticmethod
    def create_element(tag: str, text: Optional[str] = None,
                      attrib: Optional[Dict[str, str]] = None) -> ET.Element:
        element = ET.Element(tag, attrib or {})
        if text:
            element.text = text
        return element

    @staticmethod
    def add_child(parent: ET.Element, tag: str, text: Optional[str] = None,
                 attrib: Optional[Dict[str, str]] = None) -> ET.Element:
        child = ET.SubElement(parent, tag, attrib or {})
        if text:
            child.text = text
        return child

    @staticmethod
    def remove_child(parent: ET.Element, child: ET.Element) -> None:
        parent.remove(child)

    @staticmethod
    def pretty_print(element: ET.Element, indent: str = '  ') -> str:
        XMLParser._indent(element, 0, indent)
        return ET.tostring(element, encoding='unicode')

    @staticmethod
    def _indent(element: ET.Element, level: int = 0, indent: str = '  ') -> None:
        i = '\n' + level * indent
        if len(element):
            if not element.text or not element.text.strip():
                element.text = i + indent
            if not element.tail or not element.tail.strip():
                element.tail = i
            for child in element:
                XMLParser._indent(child, level + 1, indent)
            if not child.tail or not child.tail.strip():
                child.tail = i
        else:
            if level and (not element.tail or not element.tail.strip()):
                element.tail = i

class XMLBuilder:
    def __init__(self, root_tag: str):
        self.root = ET.Element(root_tag)
        self.current = self.root

    def add_element(self, tag: str, text: Optional[str] = None,
                   attrib: Optional[Dict[str, str]] = None) -> 'XMLBuilder':
        element = ET.SubElement(self.current, tag, attrib or {})
        if text:
            element.text = text
        return self

    def start_element(self, tag: str, attrib: Optional[Dict[str, str]] = None) -> 'XMLBuilder':
        self.current = ET.SubElement(self.current, tag, attrib or {})
        return self

    def end_element(self) -> 'XMLBuilder':
        if self.current != self.root:
            parent_map = {c: p for p in self.root.iter() for c in p}
            self.current = parent_map.get(self.current, self.root)
        return self

    def set_text(self, text: str) -> 'XMLBuilder':
        self.current.text = text
        return self

    def set_attribute(self, name: str, value: str) -> 'XMLBuilder':
        self.current.set(name, value)
        return self

    def build(self) -> ET.Element:
        return self.root
