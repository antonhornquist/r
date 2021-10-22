(
var r_path = (PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "r.scd").standardizePath;
var r_api = this.executeFile(r_path);
~init = r_api[\init];
~free = r_api[\free];
~new = r_api[\newCommand];
~connect = r_api[\connectCommand];
~disconnect = r_api[\disconnectCommand];
~delete = r_api[\deleteCommand];
~set = r_api[\setCommand];
~bulkset = r_api[\bulksetCommand];
~newmacro = r_api[\newmacroCommand];
~deletemacro = r_api[\deletemacroCommand];
~macroset = r_api[\macrosetCommand];
~readsample = r_api[\readsampleCommand];
~tapoutput = r_api[\tapoutputCommand];
~tapclear = r_api[\tapclearCommand];
~getTapBus = r_api[\getTapBus];
~getVisualBus = r_api[\getVisualBus];
~generateDocsForAllModules = r_api[\generateDocsForAllModules];
)
