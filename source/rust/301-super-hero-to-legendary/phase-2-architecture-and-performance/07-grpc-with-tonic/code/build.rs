fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("cargo::rerun-if-changed=proto/inventory.proto");

    // Use the protoc compiler shipped by protoc-bin-vendored, so no separate install is needed.
    let protoc = protoc_bin_vendored::protoc_bin_path()?;
    // SAFETY: a build script runs this code on its single main thread before any other thread
    // exists, so nothing can read the environment while it is being changed.
    unsafe {
        std::env::set_var("PROTOC", protoc);
    }

    tonic_prost_build::compile_protos("proto/inventory.proto")?;
    Ok(())
}
