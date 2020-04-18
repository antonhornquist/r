(
var r_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "r.scd").standardizePath;
var r_api = this.executeFile(r_path);
s.waitForBoot {
	var init = r_api[\init];
	var generateDocsForAllModules = r_api[\generateDocsForAllModules];
	var r_instance = init.value();
	postln(generateDocsForAllModules.value(r_instance));
};
)
