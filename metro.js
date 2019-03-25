inlets = 1;
outlets = 1;

var metros = []
var num_metros = 34

for(var i =0; i < num_metros; i++) {
	metros[i] = {}
		
	metros[i].id = i;
	metros[i].init_stage = 1;
	
	var a = metros[i];
	
	metros[i].task = new Task(function (m) {
		outlet(0, m.id, arguments.callee.task.iterations + m.init_stage - 1);
	}, this, a);
}

function metro_start(id, time, count, init_stage) {
	m = metros[id]
	m.id = id;
 	m.init_stage = init_stage;

	m.task.interval = time * 1000;
	m.task.repeat(count - 1, time * 1000);
}

function metro_stop(id) {
	metros[id].task.cancel();
}

function metro_set_time(id, time) {
	metros[id].task.interval = time * 1000;
}

function freebang() {
    for(var i =0; i < num_metros; i++) {
        metros[i].task.cancel();
        metros[i].task = null;

		metros[i] = {}
    }
}