module WaitingGifsHelper
  KEY_HEX = "f5ac22379b332739c23ca14db4bef565".freeze # not a secret; only defeats casual GitHub previews
  KEY_BYTES = [KEY_HEX].pack("H*").bytes.freeze

  def self.apply(bytes) # XOR is its own inverse: same method encodes and decodes
    bytes.each_byte.with_index.map { |b, i| b ^ KEY_BYTES[i % KEY_BYTES.length] }.pack("C*")
  end

  def waiting_gif_urls
    (0..9).map { |n| asset_path("wait#{n}.bin") }
  end
end
