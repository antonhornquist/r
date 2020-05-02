(
var r_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "r.scd").standardizePath;
var r = this.executeFile(r_path);
var getCoreStdModuleSpecs = r[\getCoreStdModuleSpecs];

getCoreStdModuleSpecs.value;
)
