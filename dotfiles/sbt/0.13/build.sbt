EclipseKeys.withSource := true

// Unfortunate workaround:
//   * Linux filenames have a limit of 256 characters.
//   * Consequently, I expect max-classfile-name is set to 255, or some such.
//   * This would work fine, however, when using ecryptfs, which encrypts
//     filenames, your effective filename length becomes <255 characters, say 200,
//     the remaining 55 bytes used to store crypto parameters/MACs.
//   * In this case, when scala produces 255 character filenames, the encrypted
//     filename becomes, say, 310 bytes, which is greater than 256, and so fails.
//   * Oops.
// https://github.com/scala/pickling/issues/10
scalacOptions ++= Seq("-Xmax-classfile-name", "100")
