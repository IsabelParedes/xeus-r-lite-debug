Module["onRuntimeInitialized"] = () => {
    console.log("R is ready");
    callMain();
  }

Module["preRun"] = () => {
    ENV["R_HOME"] = "/embed-env/lib/R";
    ENV["R_ENVIRON"] = "/Renviron";
    ENV["R_ENABLE_JIT"] = "0";
    let all_files = fffiles.split('\n').map(file => file.replace(/^\./, ''));
    all_files.shift();
    all_files.pop();
    console.log("ONE FILES", all_files[0]);
    for (let i = 0; i < all_files.length; i++) {
        const file = all_files[i];
        const path_in_virtual_fs = `${file}`;
        const dirname = path_in_virtual_fs.split('/').slice(0, -1).join('/');
        const filename = path_in_virtual_fs.split('/').slice(-1)[0];
        FS.mkdirTree(dirname);
        FS.createPreloadedFile(dirname, filename, `${file}`, true, true);
        // console.log(`Created file ${filename} in ${dirname}`);
        if (i == all_files.length - 1) {
            console.log("All files created");
        }
    }
};