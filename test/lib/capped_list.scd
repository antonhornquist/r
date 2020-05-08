(
var run_tests = {
	var cl = create.value(5);

	assert_array_equal.value(
		cl[\content],
		[]
	);

	push.value(cl, 7);

	assert_array_equal.value(
		cl[\content],
		[7]
	);

	push.value(cl, 4);

	assert_array_equal.value(
		cl[\content],
		[7, 4]
	);

	push.value(cl, 2);
	push.value(cl, 1);
	push.value(cl, 0);

	assert_array_equal.value(
		cl[\content],
		[7, 4, 2, 1, 0]
	);

	push.value(cl, 9);

	assert_array_equal.value(
		cl[\content],
		[4, 2, 1, 0, 9]
	);
}; 

var assert_array_equal =
{ |a, b|
	if (a != b) {
		Error("assertion failed, expected a == b, actual % != %".format(a, b)).throw;
	};
};

var create = { |capacity|
	var cl = IdentityDictionary[
		\capacity -> capacity,
		\content -> []
	];
	cl;
};

var push = { |cl, value|
	if (cl[\content].size >= cl[\capacity]) {
		cl[\content].removeAt(0);
	};
	cl[\content] = cl[\content].add(value);
};

var module = IdentityDictionary[
	\create -> create,
	\push -> push
];

run_tests.value;
module
)
