(
// utility library to use a SerialOSCEnc to mock a norns enc, implementing a subset of functions.

var arc_connect = { |n|
	var arc;

	n = n ? 1; 

	if (n != 1) {
		Error("multiple arcs not supported").throw
	};

	arc = IdentityDictionary[
		\led -> { |ring, x, val|
			SerialOSCEnc.ringSet(ring-1, x-1, val);
		},
		\all -> { |ring, val|
			SerialOSCEnc.ringAll(ring-1, val);
		}
	];

	EncDeltadef( // TODO: use Func, cleanup in a nornsemu_free function
		\nornsemu_encdelta,
		{ |ring, n, delta|
			arc[\delta].value(ring+1, n+1, delta);
		}
	);

	arc;
};


var module = IdentityDictionary[
	\arc_connect -> arc_connect,
];

module
)
