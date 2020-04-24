(
var screen_path = PathName(thisProcess.nowExecutingPath).pathOnly +/+ "test_screen.scd";
var screen = this.executeFile(screen_path);
)

~screen_move.(~screen_instance, 1, 8);
~screen_level.(~screen_instance, 15);
~screen_text.(~screen_instance, "this is it!");
~screen_update.(~screen_instance);

~screen_move.(~screen_instance, 1, 16);
~screen_level.(~screen_instance, 5);
~screen_text.(~screen_instance, "that's the thing!");
~screen_update.(~screen_instance);


