import struct CryptoKit.SHA256Digest
import struct CryptoKit.SymmetricKey
import struct Foundation.Data
import class Foundation.FileHandle
import class Foundation.ProcessInfo
import struct GenKey.Ikm
import struct GenKey.Info
import struct GenKey.KeyGenerator
import struct GenKey.Pepper
import struct GenKey.Salt
import func GenKey.key2digest

typealias IO<T> = () -> Result<T, Error>

enum GenKeyCliErr: Error {
  case invalidArgument(String)
}

func limit2filename2data(limit: Int = 1_048_576) -> (String) -> IO<Data> {
  return {
    let filename: String = $0
    return {
      let ofile: FileHandle? = FileHandle(forReadingAtPath: filename)
      guard let file = ofile else {
        return .failure(
          GenKeyCliErr.invalidArgument(
            "unable to open file: \( filename )"
          ))
      }
      defer {
        try? file.close()
      }
      return Result(catching: {
        try file.read(upToCount: limit) ?? Data()
      })
    }
  }
}

func envKey2val(_ key: String) -> IO<String> {
  let env: [String: String] = ProcessInfo.processInfo.environment
  return {
    let oval: String? = env[key]
    guard let val = oval else {
      return .failure(GenKeyCliErr.invalidArgument("env var \( key ) missing"))
    }
    return .success(val)
  }
}

func bind<T, U>(
  _ io: @escaping IO<T>,
  _ mapper: @escaping (T) -> IO<U>,
) -> IO<U> {
  return {
    let rt: Result<T, _> = io()
    return rt.flatMap {
      let t: T = $0
      return mapper(t)()
    }
  }
}

func lift<T, U>(
  _ pure: @escaping (T) -> Result<U, Error>,
) -> (T) -> IO<U> {
  return {
    let t: T = $0
    return {
      return pure(t)
    }
  }
}

func envKey2dataLimited(limit: Int = 1_048_576) -> (String) -> IO<Data> {
  let name2dat: (String) -> IO<Data> = limit2filename2data(limit: limit)
  return {
    let envKey: String = $0
    return bind(
      envKey2val(envKey),
      name2dat,
    )
  }
}

struct PublicInfo {
  public let salt: Salt
  public let info: Info
}

struct PrivateInfo {
  private let ikm: Ikm
  private let pepper: Pepper

  public static func from(ikm: Ikm, pepper: Pepper) -> Self {
    Self(ikm: ikm, pepper: pepper)
  }

  public func newKey(pub: PublicInfo, outputByteCount: Int) -> SymmetricKey {
    KeyGenerator.newKey(
      ikm: self.ikm,
      pepper: self.pepper,
      salt: pub.salt,
      info: pub.info,
      outputByteCount: outputByteCount,
    )
  }
}

struct Combined {
  public let uinfo: PublicInfo
  public let rinfo: PrivateInfo

  public func newKey(outputByteCount: Int = 32) -> SymmetricKey {
    self.rinfo.newKey(pub: self.uinfo, outputByteCount: outputByteCount)
  }
}

func printDigest(_ digest: SHA256Digest) -> IO<Void> {
  return {
    print("\( digest )")
    return .success(())
  }
}

@main
struct GenKeyCli {
  static func main() {
    let envKey2dat: (String) -> IO<Data> = envKey2dataLimited()

    let iikmDat: IO<Data> = envKey2dat("ENV_SECRET_IKM_LOCATION")
    let ipepperDat: IO<Data> = envKey2dat("ENV_SECRET_PEPPER_LOCATION")
    let isaltDat: IO<Data> = envKey2dat("ENV_PUBLIC_SALT_LOCATION")
    let iinfoDat: IO<Data> = envKey2dat("ENV_PUBLIC_INFO_LOCATION")

    let iikm: IO<Ikm> = bind(iikmDat, lift(Ikm.from))
    let ipepper: IO<Pepper> = bind(ipepperDat, lift(Pepper.from))
    let isalt: IO<Salt> = bind(isaltDat, lift(Salt.from))
    let iinfo: IO<Info> = bind(iinfoDat, lift(Info.from))

    let ipub: IO<PublicInfo> = bind(
      isalt,
      {
        let salt: Salt = $0
        return bind(
          iinfo,
          lift {
            .success(
              PublicInfo(
                salt: salt,
                info: $0,
              ))
          },
        )
      },
    )

    let ipriv: IO<PrivateInfo> = bind(
      iikm,
      {
        let ikm: Ikm = $0
        return bind(
          ipepper,
          lift {
            .success(
              .from(
                ikm: ikm,
                pepper: $0,
              )
            )
          },
        )
      },
    )

    let icombined: IO<Combined> = bind(
      ipub,
      {
        let pub: PublicInfo = $0
        return bind(
          ipriv,
          lift {
            .success(
              Combined(
                uinfo: pub,
                rinfo: $0,
              ))
          },
        )
      },
    )

    let ikey: IO<SymmetricKey> = bind(
      icombined,
      lift {
        .success($0.newKey(outputByteCount: 32))
      },
    )

    let idigest: IO<SHA256Digest> = bind(
      ikey,
      lift { .success(key2digest($0)) },
    )

    let iprint: IO<Void> = bind(
      idigest,
      printDigest,
    )

    do {
      try iprint().get()
    } catch {
      print("error: \( error )")
    }
  }
}
