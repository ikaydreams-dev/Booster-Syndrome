import struct
from typing import Any, Dict

class BinarySerializer:
    @staticmethod
    def pack_int(value: int) -> bytes:
        """Pack integer to bytes"""
        return struct.pack('!i', value)

    @staticmethod
    def unpack_int(data: bytes) -> int:
        """Unpack bytes to integer"""
        return struct.unpack('!i', data)[0]

    @staticmethod
    def pack_long(value: int) -> bytes:
        """Pack long to bytes"""
        return struct.pack('!q', value)

    @staticmethod
    def unpack_long(data: bytes) -> int:
        """Unpack bytes to long"""
        return struct.unpack('!q', data)[0]

    @staticmethod
    def pack_float(value: float) -> bytes:
        """Pack float to bytes"""
        return struct.pack('!f', value)

    @staticmethod
    def unpack_float(data: bytes) -> float:
        """Unpack bytes to float"""
        return struct.unpack('!f', data)[0]

    @staticmethod
    def pack_double(value: float) -> bytes:
        """Pack double to bytes"""
        return struct.pack('!d', value)

    @staticmethod
    def unpack_double(data: bytes) -> float:
        """Unpack bytes to double"""
        return struct.unpack('!d', data)[0]

    @staticmethod
    def pack_string(value: str) -> bytes:
        """Pack string to bytes"""
        encoded = value.encode('utf-8')
        length = len(encoded)
        return struct.pack('!I', length) + encoded

    @staticmethod
    def unpack_string(data: bytes, offset: int = 0) -> tuple:
        """Unpack bytes to string, returns (string, new_offset)"""
        length = struct.unpack('!I', data[offset:offset+4])[0]
        offset += 4
        string = data[offset:offset+length].decode('utf-8')
        return string, offset + length

    @staticmethod
    def pack_bytes(value: bytes) -> bytes:
        """Pack bytes with length prefix"""
        return struct.pack('!I', len(value)) + value

    @staticmethod
    def unpack_bytes(data: bytes, offset: int = 0) -> tuple:
        """Unpack bytes, returns (bytes, new_offset)"""
        length = struct.unpack('!I', data[offset:offset+4])[0]
        offset += 4
        value = data[offset:offset+length]
        return value, offset + length

binary_serializer = BinarySerializer()
