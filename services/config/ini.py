import re
from typing import Dict, Any, List, Optional
from collections import OrderedDict

class INIParser:
    def __init__(self):
        self.data: Dict[str, Dict[str, str]] = OrderedDict()

    def parse_file(self, filepath: str) -> None:
        with open(filepath, 'r') as f:
            self.parse_string(f.read())

    def parse_string(self, content: str) -> None:
        current_section = 'DEFAULT'
        self.data[current_section] = OrderedDict()

        for line in content.split('\n'):
            line = line.strip()

            if not line or line.startswith(';') or line.startswith('#'):
                continue

            section_match = re.match(r'^\[([^\]]+)\]$', line)
            if section_match:
                current_section = section_match.group(1)
                if current_section not in self.data:
                    self.data[current_section] = OrderedDict()
                continue

            key_value_match = re.match(r'^([^=]+)=(.*)$', line)
            if key_value_match:
                key = key_value_match.group(1).strip()
                value = key_value_match.group(2).strip()
                self.data[current_section][key] = value

    def to_string(self) -> str:
        lines = []

        for section, values in self.data.items():
            if section != 'DEFAULT' or values:
                if section != 'DEFAULT':
                    lines.append(f'[{section}]')

                for key, value in values.items():
                    lines.append(f'{key}={value}')

                lines.append('')

        return '\n'.join(lines)

    def get(self, section: str, key: str, default: Optional[str] = None) -> Optional[str]:
        return self.data.get(section, {}).get(key, default)

    def get_int(self, section: str, key: str, default: int = 0) -> int:
        value = self.get(section, key)
        if value is None:
            return default
        try:
            return int(value)
        except ValueError:
            return default

    def get_float(self, section: str, key: str, default: float = 0.0) -> float:
        value = self.get(section, key)
        if value is None:
            return default
        try:
            return float(value)
        except ValueError:
            return default

    def get_bool(self, section: str, key: str, default: bool = False) -> bool:
        value = self.get(section, key)
        if value is None:
            return default
        return value.lower() in ('true', 'yes', '1', 'on')

    def get_list(self, section: str, key: str, separator: str = ',') -> List[str]:
        value = self.get(section, key)
        if value is None:
            return []
        return [v.strip() for v in value.split(separator)]

    def set(self, section: str, key: str, value: Any) -> None:
        if section not in self.data:
            self.data[section] = OrderedDict()
        self.data[section][key] = str(value)

    def remove(self, section: str, key: Optional[str] = None) -> bool:
        if key is None:
            if section in self.data:
                del self.data[section]
                return True
            return False
        else:
            if section in self.data and key in self.data[section]:
                del self.data[section][key]
                return True
            return False

    def has_section(self, section: str) -> bool:
        return section in self.data

    def has_key(self, section: str, key: str) -> bool:
        return section in self.data and key in self.data[section]

    def sections(self) -> List[str]:
        return [s for s in self.data.keys() if s != 'DEFAULT']

    def keys(self, section: str) -> List[str]:
        return list(self.data.get(section, {}).keys())

    def items(self, section: str) -> List[tuple]:
        return list(self.data.get(section, {}).items())

    def merge(self, other: 'INIParser') -> None:
        for section, values in other.data.items():
            if section not in self.data:
                self.data[section] = OrderedDict()
            self.data[section].update(values)

    def clear(self) -> None:
        self.data.clear()
        self.data['DEFAULT'] = OrderedDict()

class ConfigBuilder:
    def __init__(self):
        self.parser = INIParser()
        self.current_section = 'DEFAULT'

    def section(self, name: str) -> 'ConfigBuilder':
        self.current_section = name
        if name not in self.parser.data:
            self.parser.data[name] = OrderedDict()
        return self

    def set(self, key: str, value: Any) -> 'ConfigBuilder':
        self.parser.set(self.current_section, key, value)
        return self

    def build(self) -> INIParser:
        return self.parser

class EnvParser:
    @staticmethod
    def parse_file(filepath: str) -> Dict[str, str]:
        env = {}
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue

                match = re.match(r'^([^=]+)=(.*)$', line)
                if match:
                    key = match.group(1).strip()
                    value = match.group(2).strip()

                    if (value.startswith('"') and value.endswith('"')) or \
                       (value.startswith("'") and value.endswith("'")):
                        value = value[1:-1]

                    env[key] = value

        return env

    @staticmethod
    def to_string(env: Dict[str, str]) -> str:
        lines = []
        for key, value in env.items():
            if ' ' in value or '"' in value or "'" in value:
                value = f'"{value}"'
            lines.append(f'{key}={value}')
        return '\n'.join(lines)
