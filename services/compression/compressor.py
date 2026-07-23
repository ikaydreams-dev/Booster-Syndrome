import gzip
import zlib
import bz2

class Compressor:
    def compress_gzip(self, data):
        """Compress data using gzip"""
        if isinstance(data, str):
            data = data.encode('utf-8')

        return gzip.compress(data)

    def decompress_gzip(self, data):
        """Decompress gzip data"""
        return gzip.decompress(data)

    def compress_zlib(self, data):
        """Compress data using zlib"""
        if isinstance(data, str):
            data = data.encode('utf-8')

        return zlib.compress(data)

    def decompress_zlib(self, data):
        """Decompress zlib data"""
        return zlib.decompress(data)

    def compress_bz2(self, data):
        """Compress data using bz2"""
        if isinstance(data, str):
            data = data.encode('utf-8')

        return bz2.compress(data)

    def decompress_bz2(self, data):
        """Decompress bz2 data"""
        return bz2.decompress(data)

    def get_compression_ratio(self, original, compressed):
        """Calculate compression ratio"""
        return len(compressed) / len(original)
