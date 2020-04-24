(
var screen_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ ".." +/+ "util" +/+ "norns_engine_tester" +/+ "screen.scd";
var screen = this.executeFile(screen_path);
)
~screen_move.(~screen_instance, 5, 5);
~screen_level.(~screen_instance, 15);
~screen_text.(~screen_instance, "this is it!");
~screen_update.(~screen_instance);

~screen_instance