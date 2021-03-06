package;

import turnwing.*;
import turnwing.provider.*;
import turnwing.template.*;
import tink.unit.*;
import tink.unit.Assert.*;
import tink.testrunner.*;

using tink.CoreApi;

class RunTests {

	static function main() {
		Runner.run(TestBatch.make([
			new LocalizerTest()
		])).handle(Runner.exit);
	}
	
}

interface MyLocale {
	var normal(default, null):String;
	var getter(get, null):String;
	function hello(name:String):String;
}

interface InvalidLocale {
	function foo(name:String):String;
}

interface ParentLocale {
	var normal(default, null):MyLocale;
	var getter(get, null):MyLocale;
}

@:asserts
class LocalizerTest {
	var reader:StringReader;
	var template:Template;
	
	public function new() {}
	
	@:before
	public function before() {
		reader = new FileReader(function(lang) return './tests/data/$lang.json');
		template = new HaxeTemplate();
		return Noise;
	}
	
	public function localize() {
		var loc = new Manager<MyLocale>(new JsonProvider(reader), template);
		return loc.prepare(['en'])
			.next(function(o) {
				asserts.assert(loc.language('en').hello('World') == 'Hello, World!');
				asserts.assert(loc.language('en').normal == 'Hello, World!');
				asserts.assert(loc.language('en').getter == 'Hello, World!');
				return asserts.done();
			});
	}
	
	public function noData() {
		var loc = new Manager<MyLocale>(new JsonProvider(reader), template);
		return loc.prepare(['dummy'])
			.map(function(o) return assert(!o.isSuccess()));
	}
	
	public function invalid() {
		var loc = new Manager<InvalidLocale>(new JsonProvider(reader), template);
		return loc.prepare(['en'])
			.map(function(o) return assert(!o.isSuccess()));
	}
	
	public function child() {
		var reader = new FileReader(function(lang) return './tests/data/child-$lang.json');
		var loc = new Manager<ParentLocale>(new JsonProvider(reader), template);
		return loc.prepare(['en'])
			.next(function(o) {
				var en = loc.language('en');
				asserts.assert(en.normal.hello('World') == 'Hello, World!');
				asserts.assert(en.normal.normal == 'Hello, World!');
				asserts.assert(en.normal.getter == 'Hello, World!');
				asserts.assert(en.getter.hello('World') == 'Hello, World!');
				asserts.assert(en.getter.normal == 'Hello, World!');
				asserts.assert(en.getter.getter == 'Hello, World!');
				return asserts.done();
			});
	}
}