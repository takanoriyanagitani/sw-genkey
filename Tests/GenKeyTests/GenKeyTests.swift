import Testing

import struct CryptoKit.SymmetricKey
import struct Foundation.Data

@testable import struct GenKey.Ikm
@testable import struct GenKey.Info
@testable import struct GenKey.KeyGenerator
@testable import struct GenKey.Pepper
@testable import struct GenKey.Salt

@Suite("Derive Key")
struct DeriveKeyTests {

  @Test("Derives a key")
  func testDerive() throws {

    let testIkmBytes: [UInt8] = PackageResources.ikm_dat
    let testIkmData: Data = Data(testIkmBytes)
    let rtestIkm: Result<Ikm, _> = Ikm.from(secret: testIkmData)
    let testIkm: Ikm = try rtestIkm.get()

    let testSaltBytes: [UInt8] = PackageResources.salt_dat
    let testSaltData: Data = Data(testSaltBytes)
    let rtestSalt: Result<Salt, _> = Salt.from(salt: testSaltData)
    let testSalt: Salt = try rtestSalt.get()

    let testInfoBytes: [UInt8] = PackageResources.info_dat
    let testInfoData: Data = Data(testInfoBytes)
    let rtestInfo: Result<Info, _> = Info.from(info: testInfoData)
    let testInfo: Info = try rtestInfo.get()

    let remptyPepper: Result<Pepper, _> = Pepper.from(secret: Data())
    let emptyPepper: Pepper = try remptyPepper.get()

    let key: SymmetricKey = KeyGenerator.newKey(
      ikm: testIkm,
      pepper: emptyPepper,
      salt: testSalt,
      info: testInfo,
      outputByteCount: 42,
    )

    let testExpkBytes: [UInt8] = PackageResources.expected_dat
    let testExpkData: Data = Data(testExpkBytes)
    let expectedKey: SymmetricKey = SymmetricKey(data: testExpkData)

    #expect(expectedKey == key)

  }

}
