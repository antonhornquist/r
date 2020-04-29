(
// utility library to use a SerialOSCGrid to mock a norns grid, implementing a subset of functions.

var grid_connect = { |n|
	var grid;

	n = n ? 1; 

	if (n != 1) {
		Error("multiple grids not supported").throw
	};

	grid = ();
	grid.led_ = { |self, x, y, val|
		SerialOSCGrid.ledLevelSet(x-1, y-1, val);
	};
	grid.all_ = { |self, val|
		SerialOSCGrid.ledLevelAll(val);
	};
	grid.cols_ = { |self|
		SerialOSCGrid.numCols;
	};
	grid.rows_ = { |self|
		SerialOSCGrid.numRows;
	};

	GridKeydef( // TODO: use Func, cleanup in a nornsemu_free function
		\nornsemu_gridkey,
		{ |x, y, state|
			grid[\key].value(x+1, y+1, state);
		}
	);

	grid;
};

var module = IdentityDictionary[
	\grid_connect -> grid_connect,
];

module
)
