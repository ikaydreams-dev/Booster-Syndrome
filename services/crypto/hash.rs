use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

pub struct HashUtils;

impl HashUtils {
    pub fn hash_string(s: &str) -> u64 {
        let mut hasher = DefaultHasher::new();
        s.hash(&mut hasher);
        hasher.finish()
    }

    pub fn hash_bytes(bytes: &[u8]) -> u64 {
        let mut hasher = DefaultHasher::new();
        bytes.hash(&mut hasher);
        hasher.finish()
    }

    pub fn simple_checksum(data: &[u8]) -> u32 {
        data.iter().map(|&b| b as u32).sum()
    }

    pub fn xor_checksum(data: &[u8]) -> u8 {
        data.iter().fold(0u8, |acc, &b| acc ^ b)
    }

    pub fn fnv1a_hash(data: &[u8]) -> u64 {
        const FNV_OFFSET_BASIS: u64 = 14695981039346656037;
        const FNV_PRIME: u64 = 1099511628211;

        let mut hash = FNV_OFFSET_BASIS;
        for &byte in data {
            hash ^= byte as u64;
            hash = hash.wrapping_mul(FNV_PRIME);
        }
        hash
    }

    pub fn djb2_hash(data: &[u8]) -> u64 {
        let mut hash = 5381u64;
        for &byte in data {
            hash = hash.wrapping_mul(33).wrapping_add(byte as u64);
        }
        hash
    }

    pub fn sdbm_hash(data: &[u8]) -> u64 {
        let mut hash = 0u64;
        for &byte in data {
            hash = (byte as u64)
                .wrapping_add(hash.wrapping_shl(6))
                .wrapping_add(hash.wrapping_shl(16))
                .wrapping_sub(hash);
        }
        hash
    }
}

pub struct BloomFilter {
    bits: Vec<bool>,
    size: usize,
    hash_count: usize,
}

impl BloomFilter {
    pub fn new(size: usize, hash_count: usize) -> Self {
        BloomFilter {
            bits: vec![false; size],
            size,
            hash_count,
        }
    }

    fn hash(&self, data: &[u8], seed: usize) -> usize {
        let mut hash = seed as u64;
        for &byte in data {
            hash = hash.wrapping_mul(31).wrapping_add(byte as u64);
        }
        (hash as usize) % self.size
    }

    pub fn insert(&mut self, data: &[u8]) {
        for i in 0..self.hash_count {
            let index = self.hash(data, i);
            self.bits[index] = true;
        }
    }

    pub fn contains(&self, data: &[u8]) -> bool {
        for i in 0..self.hash_count {
            let index = self.hash(data, i);
            if !self.bits[index] {
                return false;
            }
        }
        true
    }

    pub fn clear(&mut self) {
        self.bits.fill(false);
    }
}
