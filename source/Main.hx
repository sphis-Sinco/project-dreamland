package;

import flixel.FlxG;
import flixel.FlxGame;
import haxe.Json;
import lime.app.Application;
import openfl.display.Sprite;

using StringTools;

class Main extends Sprite
{
	public static var updateVersion:String;

	public function new()
	{
		FlxG.save.bind('dreamland', Application.current.meta.get('company'));
		var needUpdate = false;
		#if !hl
		trace('checking for update');
		var http = new haxe.Http("https://raw.githubusercontent.com/sphis-Sinco/project-dreamland/refs/heads/master/version.txt");

		http.onData = function(data:String)
		{
			updateVersion = data.split('\n')[0].trim();
			var curVersion:String = Application.current.meta.get('version').trim();
			trace('version online: ' + updateVersion + ', your version: ' + curVersion);
			if (updateVersion != curVersion)
			{
				trace('versions arent matching!');
				needUpdate = true;
			}
		}

		http.onError = function(error)
		{
			trace('error: $error');
			FlxG.save.data.latest_version = Application.current.meta.get('version');
		}

		http.request();
		#end
		
		super();
		addChild(new FlxGame(0, 0, (needUpdate) ? OutdatedState : MenuState));
	}
}
