fn main() {
    println!("cargo::rerun-if-changed=csrc/checksum.c");
    println!("cargo::rerun-if-changed=csrc/checksum.h");
    cc::Build::new()
        .file("csrc/checksum.c")
        .warnings(true)
        .compile("c101_checksum");
}
