(
var r_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "r.scd").standardizePath;
var r_api = this.executeFile(r_path);

// TODO: this ought to be possible to write without booting an r instance
s.waitForBoot {
	var init = r_api[\init];
	var generateDocsForAllModules = r_api[\generateDocsForAllModules];
	var r = init.value();
	postln(generateDocsForAllModules.value(r));
};
)
