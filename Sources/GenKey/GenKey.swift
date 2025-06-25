import struct CryptoKit.HKDF
import struct CryptoKit.SHA256
import struct CryptoKit.SHA256Digest
import struct CryptoKit.SymmetricKey
import struct Foundation.Data

public enum GenKeyErr: Error {
  case invalidArgument(String)
}

public struct Ikm {
  private let secret: Data

  public static func from(secret: Data) -> Result<Self, Error> {
    guard 22 <= secret.count else {
      return .failure(GenKeyErr.invalidArgument("too short secret"))
    }
    return .success(Self(secret: secret))
  }

  public func toKey() -> SymmetricKey { SymmetricKey(data: self.secret) }

  public func toKey(pepperSecret: Data) -> SymmetricKey {
    var combined: Data = Data()
    combined.append(pepperSecret)
    combined.append(self.secret)
    return SymmetricKey(data: combined)
  }
}

public struct Pepper {
  private let secret: Data

  public static func from(secret: Data) -> Result<Self, Error> {
    return .success(Self(secret: secret))
  }

  public func toKey(ikm: Ikm) -> SymmetricKey {
    ikm.toKey(pepperSecret: self.secret)
  }
}

public struct Salt {
  public let salt: Data

  public static func from(salt: Data) -> Result<Self, Error> {
    guard 13 <= salt.count else {
      return .failure(GenKeyErr.invalidArgument("too short salt"))
    }
    return .success(Self(salt: salt))
  }
}

public struct Info {
  public let info: Data

  public static func from(info: Data) -> Result<Self, Error> {
    guard 10 <= info.count else {
      return .failure(GenKeyErr.invalidArgument("too short info"))
    }
    return .success(Self(info: info))
  }

  public static func from(
    fqdn: String,
    codeName: String,
  ) -> Result<Self, Error> {
    let fc: String = fqdn + codeName
    let dat: Data = fc.data(using: .utf8) ?? Data()
    return Self.from(info: dat)
  }
}

public struct KeyGenerator {
  private let ikm: Ikm
  private let pepper: Pepper
  public let salt: Salt
  public let info: Info

  private func deriveKey(outputByteCount: Int = 32) -> SymmetricKey {
    HKDF<SHA256>.deriveKey(
      inputKeyMaterial: self.pepper.toKey(ikm: self.ikm),
      salt: self.salt.salt,
      info: self.info.info,
      outputByteCount: outputByteCount,
    )
  }

  public static func newKey(
    ikm: Ikm,
    pepper: Pepper,
    salt: Salt,
    info: Info,
    outputByteCount: Int = 32,
  ) -> SymmetricKey {
    let kgen: KeyGenerator = Self(
      ikm: ikm,
      pepper: pepper,
      salt: salt,
      info: info,
    )
    return kgen.deriveKey(outputByteCount: outputByteCount)
  }
}

public func key2digest(_ key: SymmetricKey) -> SHA256Digest {
  key.withUnsafeBytes {
    let raw: UnsafeRawBufferPointer = $0
    return SHA256.hash(data: raw)
  }
}
