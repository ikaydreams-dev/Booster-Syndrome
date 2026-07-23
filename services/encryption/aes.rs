use std::collections::HashMap;

pub struct SimpleCipher {
    shift: u8,
}

impl SimpleCipher {
    pub fn new(shift: u8) -> Self {
        SimpleCipher { shift }
    }

    pub fn encrypt_char(&self, c: char) -> char {
        if c.is_ascii_alphabetic() {
            let base = if c.is_ascii_lowercase() { b'a' } else { b'A' };
            let shifted = ((c as u8 - base + self.shift) % 26) + base;
            shifted as char
        } else {
            c
        }
    }

    pub fn decrypt_char(&self, c: char) -> char {
        if c.is_ascii_alphabetic() {
            let base = if c.is_ascii_lowercase() { b'a' } else { b'A' };
            let shifted = ((c as u8 - base + 26 - self.shift) % 26) + base;
            shifted as char
        } else {
            c
        }
    }

    pub fn encrypt(&self, text: &str) -> String {
        text.chars().map(|c| self.encrypt_char(c)).collect()
    }

    pub fn decrypt(&self, text: &str) -> String {
        text.chars().map(|c| self.decrypt_char(c)).collect()
    }
}

pub struct VigenereCipher {
    key: String,
}

impl VigenereCipher {
    pub fn new(key: &str) -> Self {
        VigenereCipher {
            key: key.to_lowercase(),
        }
    }

    pub fn encrypt(&self, text: &str) -> String {
        let mut result = String::new();
        let mut key_index = 0;

        for c in text.chars() {
            if c.is_ascii_alphabetic() {
                let base = if c.is_ascii_lowercase() { b'a' } else { b'A' };
                let key_char = self.key.chars().nth(key_index % self.key.len()).unwrap();
                let shift = key_char as u8 - b'a';
                let encrypted = ((c as u8 - base + shift) % 26) + base;
                result.push(encrypted as char);
                key_index += 1;
            } else {
                result.push(c);
            }
        }

        result
    }

    pub fn decrypt(&self, text: &str) -> String {
        let mut result = String::new();
        let mut key_index = 0;

        for c in text.chars() {
            if c.is_ascii_alphabetic() {
                let base = if c.is_ascii_lowercase() { b'a' } else { b'A' };
                let key_char = self.key.chars().nth(key_index % self.key.len()).unwrap();
                let shift = key_char as u8 - b'a';
                let decrypted = ((c as u8 - base + 26 - shift) % 26) + base;
                result.push(decrypted as char);
                key_index += 1;
            } else {
                result.push(c);
            }
        }

        result
    }
}

pub struct SubstitutionCipher {
    mapping: HashMap<char, char>,
    reverse_mapping: HashMap<char, char>,
}

impl SubstitutionCipher {
    pub fn new(key: &str) -> Result<Self, &'static str> {
        if key.len() != 26 {
            return Err("Key must be 26 characters");
        }

        let mut mapping = HashMap::new();
        let mut reverse_mapping = HashMap::new();
        let alphabet = "abcdefghijklmnopqrstuvwxyz";

        for (i, ch) in alphabet.chars().enumerate() {
            let key_char = key.chars().nth(i).unwrap().to_ascii_lowercase();
            mapping.insert(ch, key_char);
            mapping.insert(ch.to_ascii_uppercase(), key_char.to_ascii_uppercase());
            reverse_mapping.insert(key_char, ch);
            reverse_mapping.insert(key_char.to_ascii_uppercase(), ch.to_ascii_uppercase());
        }

        Ok(SubstitutionCipher {
            mapping,
            reverse_mapping,
        })
    }

    pub fn encrypt(&self, text: &str) -> String {
        text.chars()
            .map(|c| *self.mapping.get(&c).unwrap_or(&c))
            .collect()
    }

    pub fn decrypt(&self, text: &str) -> String {
        text.chars()
            .map(|c| *self.reverse_mapping.get(&c).unwrap_or(&c))
            .collect()
    }
}

pub struct XORCipher {
    key: Vec<u8>,
}

impl XORCipher {
    pub fn new(key: &[u8]) -> Self {
        XORCipher {
            key: key.to_vec(),
        }
    }

    pub fn encrypt(&self, data: &[u8]) -> Vec<u8> {
        data.iter()
            .enumerate()
            .map(|(i, &b)| b ^ self.key[i % self.key.len()])
            .collect()
    }

    pub fn decrypt(&self, data: &[u8]) -> Vec<u8> {
        self.encrypt(data)
    }
}

pub fn base64_encode(data: &[u8]) -> String {
    const CHARSET: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let mut result = String::new();

    for chunk in data.chunks(3) {
        let mut buf = [0u8; 3];
        for (i, &byte) in chunk.iter().enumerate() {
            buf[i] = byte;
        }

        result.push(CHARSET[(buf[0] >> 2) as usize] as char);
        result.push(CHARSET[(((buf[0] & 0x03) << 4) | (buf[1] >> 4)) as usize] as char);

        if chunk.len() > 1 {
            result.push(CHARSET[(((buf[1] & 0x0F) << 2) | (buf[2] >> 6)) as usize] as char);
        } else {
            result.push('=');
        }

        if chunk.len() > 2 {
            result.push(CHARSET[(buf[2] & 0x3F) as usize] as char);
        } else {
            result.push('=');
        }
    }

    result
}

pub fn hex_encode(data: &[u8]) -> String {
    data.iter()
        .map(|b| format!("{:02x}", b))
        .collect()
}

pub fn hex_decode(s: &str) -> Result<Vec<u8>, &'static str> {
    if s.len() % 2 != 0 {
        return Err("Invalid hex string length");
    }

    (0..s.len())
        .step_by(2)
        .map(|i| {
            u8::from_str_radix(&s[i..i + 2], 16)
                .map_err(|_| "Invalid hex character")
        })
        .collect()
}
